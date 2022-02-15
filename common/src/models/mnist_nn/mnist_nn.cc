/*
 * Copyright 2021 The CFU-Playground Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "models/mnist_nn/mnist_nn.h"

#include <stdio.h>

#include "menu.h"
#include "models/mnist_nn/image_0.cc"
#include "models/mnist_nn/image_1.cc"
#include "models/mnist_nn/image_2.cc"
#include "models/mnist_nn/model_mnist_nn.h"
#include "tflite.h"

extern "C" {  
#include "fb_util.h"
};

#define NUM_GOLDEN 3
struct golden_test_nn {
  const unsigned char *data;
  int8_t expected;
};

struct golden_test_nn golden_test[] = {
    {image_0, 7},
    {image_1, 2},
    {image_2, 1},
};

// Initialize everything once
// deallocate tensors when done
static void mnist_nn_init(void) {
  tflite_load_model(model_mnist_nn, model_mnist_nn_len);
}

// Run classification, after input has been loaded
static int32_t mnist_nn_classify() {
  printf("Running mnist_nn\n");
  tflite_classify();

  // Process the inference results.
  int8_t* output = tflite_get_output();
  int pred_score = -300; 
  int pred_idx = -1; 
  for(int i = 0; i < 10; i++){
    // printf("%d\n",output[i]);
    if(output[i] > pred_score){
      pred_score = output[i]; 
      pred_idx = i;
    }
  }
  return pred_idx;
}

static void do_golden_tests() {
  bool failed = false;

#ifdef CSR_VIDEO_FRAMEBUFFER_BASE
  char msg_buff[256] = { 0 };
#endif  

  for (size_t i = 0; i < NUM_GOLDEN; i++) {
    tflite_set_input_unsigned(golden_test[i].data);
    int actual = mnist_nn_classify();
    int expected = golden_test[i].expected;
    if (actual != expected) {
      failed = true;
      printf("*** Golden test %d failed: %d (actual) != %d (expected))\n", i, actual, expected);
    }

#ifdef CSR_VIDEO_FRAMEBUFFER_BASE
    fb_clear();
    memset(msg_buff, 0x00, sizeof(msg_buff));
    snprintf(msg_buff, sizeof(msg_buff), "Run golden tests %d", i);
    fb_draw_string(0, 10, 0x007FFF00, (const char *)msg_buff);
    fb_draw_buffer(0, 50, 160, 160, (const uint8_t *)golden_test[i].data, 3);
    memset(msg_buff, 0x00, sizeof(msg_buff));
    snprintf(msg_buff, sizeof(msg_buff), "Result is %d, Expected is %d", actual, expected);
    fb_draw_string(0, 220, 0x007FFF00, (const char *)msg_buff);
    flush_cpu_dcache();
    flush_l2_cache();
#endif  
  }

  if (failed) {
    puts("FAIL Golden tests failed");
  } else {
    puts("OK   Golden tests passed");
  }
}

static struct Menu MENU = {
    "Tests for mnist_nn model",
    "mnist_nn",
    {
        MENU_ITEM('g', "Run golden tests (check for expected outputs)", do_golden_tests),
        MENU_END,
    },
};

// For integration into menu system
void mnist_nn_menu() {
  mnist_nn_init();

#ifdef CSR_VIDEO_FRAMEBUFFER_BASE
  fb_init();
  flush_cpu_dcache();
  flush_l2_cache();
#endif

  menu_run(&MENU);
}
