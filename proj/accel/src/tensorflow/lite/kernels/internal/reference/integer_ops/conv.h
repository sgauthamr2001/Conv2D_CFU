/* Copyright 2019 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

#define L 8
#ifndef TENSORFLOW_LITE_KERNELS_INTERNAL_REFERENCE_INTEGER_OPS_CONV_H_
#define TENSORFLOW_LITE_KERNELS_INTERNAL_REFERENCE_INTEGER_OPS_CONV_H_
// #include "perf.h"
#include <cstdio>
#include "cfu.h"
#include <stdio.h>
#include "tensorflow/lite/kernels/internal/common.h"

namespace tflite {
namespace reference_integer_ops {

// Fixed-point per-channel-quantization convolution reference kernel.
inline void ConvPerChannel(
    const ConvParams& params, const int32_t* output_multiplier,
    const int32_t* output_shift, const RuntimeShape& input_shape,
    const int8_t* input_data, const RuntimeShape& filter_shape,
    const int8_t* filter_data, const RuntimeShape& bias_shape,
    const int32_t* bias_data, const RuntimeShape& output_shape,
    int8_t* output_data) {
    
  // Get parameters.
  const int pad_width = params.padding_values.width;
  const int pad_height = params.padding_values.height;


  // Set min and max value of the output.
  const int32_t output_activation_min = params.quantized_activation_min;
  const int32_t output_activation_max = params.quantized_activation_max;

  // Consistency check.
  TFLITE_DCHECK_LE(output_activation_min, output_activation_max);
  TFLITE_DCHECK_EQ(input_shape.DimensionsCount(), 4);
  TFLITE_DCHECK_EQ(filter_shape.DimensionsCount(), 4);
  TFLITE_DCHECK_EQ(output_shape.DimensionsCount(), 4);
  const int input_depth = MatchingDim(input_shape, 3, filter_shape, 3);
  const int output_depth = MatchingDim(filter_shape, 0, output_shape, 3);
  if (bias_data){
    TFLITE_DCHECK_EQ(bias_shape.FlatSize(), output_depth);
  }
 
	
  // Check dimensions of the tensors.
  const int input_height = input_shape.Dims(1);
  const int input_width = input_shape.Dims(2);
  const int output_height = output_shape.Dims(1);
  const int output_width = output_shape.Dims(2);
  
  if (input_depth == 1){
    for (int out_channel = 0; out_channel < output_depth; out_channel += L){
        for (int out_y = 0; out_y < output_height; out_y += 4){
            for (int out_x = 0; out_x < output_width; out_x += 4){
  			  
                const int in_y = out_y - 1;
                const int in_x = out_x - 1;
        	
                bool in_image;	 
                cfu_op0(3, 0, 0);     // Sets accumulators and compute counter to zero 
                cfu_op0(4, 0, 0);     // Sets memory counter to zero 
						
                uint32_t a;
                uint32_t b; 
                
                // perf_enable_counter(0);   
                
                // No SIMD addition for the image it-self as it is single channel input    	
                
                for (int id = 0; id < 6; id++){
           		
                    a = 0x80808080;      // Keeps track for the zero padding of input activations 
                    b = 0x80808080;
            			
                    in_image = (in_x >= 0) && (in_x < 28) && (in_y + id >= 0) && (in_y + id < 28);
                    if(in_image)
                        a = uint8_t(input_data[Offset(input_shape, 0, in_y + id, in_x, 0)]);
		    	    		    
                    in_image = (in_x + 1 >= 0) && (in_x + 1 < 28) && (in_y + id >= 0) && (in_y + id < 28);
                    if(in_image)
                        b = uint8_t(input_data[Offset(input_shape, 0, in_y + id, in_x + 1, 0)]);	
		    	    			
                    cfu_op0(5, a, b);        // Performs write to the accelerator scratchpad
		          	
                    a = 0x80808080;
                    b = 0x80808080;
            					          	
                    in_image = (in_x + 2 >= 0) && (in_x + 2 < 28) && (in_y + id >= 0) && (in_y + id < 28);
                    if(in_image) 
                        a = uint8_t(input_data[Offset(input_shape, 0, in_y + id, in_x + 2, 0)]);
		          	
                    in_image = (in_x + 3 >= 0) && (in_x + 3 < 28) && (in_y + id >= 0) && (in_y + id < 28);
                    if(in_image)
                        b = uint8_t(input_data[Offset(input_shape, 0, in_y + id, in_x + 3, 0)]);	
		          		          	
                    cfu_op0(5, a, b); 
		          	
                    a = 0x80808080;
                    b = 0x80808080;
            					          	
                    in_image = (in_x + 4 >= 0) && (in_x + 4 < 28) && (in_y + id >= 0) && (in_y + id < 28);
                    if(in_image) 		          	
                        a = uint8_t(input_data[Offset(input_shape, 0, in_y + id, in_x + 4, 0)]);
		          	
                    in_image = (in_x + 5 >= 0) && (in_x + 5 < 28) && (in_y + id >= 0) && (in_y + id < 28);
                    if(in_image)
                        b = uint8_t(input_data[Offset(input_shape, 0, in_y + id, in_x + 5, 0)]);	
		          	          	
                    cfu_op0(5, a, b);

                }
                
                // perf_disable_counter(0);
                
                // perf_enable_counter(0); 
                
                // Accumulation of results by sending weights 
              	
                for (uint8_t i = 0; i < L; i++){ 
	      	
                    cfu_op0(4, 0, 0); 
	      		
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 0, 0, 0)]);
                    cfu_op0(1, a, i); 
						
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 0, 1, 0)]);
                    cfu_op0(1, a, i); 
						
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 0, 2, 0)]);
                    cfu_op0(1, a, i); 
						
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 1, 0, 0)]);
                    cfu_op0(1, a, i); 
						
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 1, 1, 0)]);
                    cfu_op0(1, a, i); 
						
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 1, 2, 0)]);
                    cfu_op0(1, a, i); 
						
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 2, 0, 0)]);
                    cfu_op0(1, a, i); 
						
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 2, 1, 0)]);
                    cfu_op0(1, a, i); 
						
                    a = uint8_t(filter_data[Offset(filter_shape, out_channel + i, 2, 2, 0)]);
                    cfu_op0(1, a, i); 
						
                    cfu_op0(1, 0, i);
                    cfu_op0(1, 0, i); 
                    cfu_op0(1, 0, i); 
	      		
                }
                
                // perf_disable_counter(0);
					
                int32_t acc; 
                int id = 0;
                
                // perf_enable_counter(0);

                for (int i = 0; i < 4; i++){
                    for (int j = 0; j < 4; j++){
                        for (int k = 0; k < L; k++){
          	
                            acc = cfu_op0(2, id, k);
            									         	
                            if (bias_data){
                                acc += bias_data[out_channel + k];
                            } 
                            
                            acc = MultiplyByQuantizedMultiplier(acc, output_multiplier[out_channel], output_shift[out_channel]);
                            acc -= 128; //  output_offset;
                            acc = std::max(acc, output_activation_min);
                            acc = std::min(acc, output_activation_max);
                            output_data[Offset(output_shape, 0, out_y + i, out_x + j, out_channel + k)] = static_cast<int8_t>(acc);
                        }
                        id += 1;
                    }
                }
                
                // perf_disable_counter(0);
            }
        }   
    }
  }	
  else{
    for (int out_channel = 0; out_channel < output_depth; out_channel += L){
        for (int out_y = 0; out_y < output_height; out_y += 4){
            for (int out_x = 0; out_x < output_width; out_x += 4){
                const int in_y = out_y - pad_height;
                const int in_x = out_x - pad_width;		
        	
                cfu_op0(3, 0, 0);      // Sets accumulators and compute counter to zero 
				
		 // Each time four elements across the input channel are sent exploiting SIMD nature 
                for (int in_channel = 0; in_channel < input_depth; in_channel += 4){
			
                    cfu_op0(4, 0, 0);   // Sets the memory counter to zero 
						
                    uint32_t a;
                    uint32_t b; 
           		       
                    bool in_image;
                    
                    // perf_enable_counter(0);
                    
                    // Accumulating the input scratch-pad 
                    for (int id = 0; id < 6; id++){
           		
                        a = 0x80808080;
                        b = 0x80808080;
           	
                        in_image = (in_x >= 0) && (in_x < input_width) && (in_y + id >= 0) && (in_y + id < input_height);
                        if(in_image)                
                            a = *((uint32_t *)(input_data + Offset(input_shape, 0, in_y + id, in_x, in_channel)));

                        in_image = (in_x + 1 >= 0) && (in_x + 1 < input_width) && (in_y + id >= 0) && (in_y + id < input_height);
                        if(in_image)
                            b = *((uint32_t *)(input_data + Offset(input_shape, 0, in_y + id, in_x + 1, in_channel)));	
      	
                        cfu_op0(5, a, b);           	

                        a = 0x80808080;
                        b = 0x80808080;

                        in_image = (in_x + 2 >= 0) && (in_x + 2 < input_width) && (in_y + id >= 0) && (in_y + id < input_height);
                        if(in_image)
                            a = *((uint32_t *)(input_data + Offset(input_shape, 0, in_y + id, in_x + 2, in_channel)));
		          	
                        in_image = (in_x + 3 >= 0) && (in_x + 3 < input_width) && (in_y + id >= 0) && (in_y + id < input_height);
                        if(in_image)
                            b = *((uint32_t *)(input_data + Offset(input_shape, 0, in_y + id, in_x + 3, in_channel)));	
		          		          	          	
                        cfu_op0(5, a, b); 
		          	
                        a = 0x80808080;
                        b = 0x80808080;
		          	
                        in_image = (in_x + 4 >= 0) && (in_x + 4 < input_width) && (in_y + id >= 0) && (in_y + id < input_height);
                        if(in_image)
                            a = *((uint32_t *)(input_data + Offset(input_shape, 0, in_y + id, in_x + 4, in_channel)));
		          	
                        in_image = (in_x + 5 >= 0) && (in_x + 5 < input_width) && (in_y + id >= 0) && (in_y + id < input_height);
                        if(in_image)
                            b = *((uint32_t *)(input_data + Offset(input_shape, 0, in_y + id, in_x + 5, in_channel)));		          	
		          
                        cfu_op0(5, a, b);
              	
                    }
                    // perf_disable_counter(0);
              	
              	     // perf_enable_counter(0); 
              	     
              	     // Sending weights for accumulation 
                    for (uint8_t i = 0; i < L; i++){ 
					
                        cfu_op0(4, 0, 0); 
            	
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 0, 0, in_channel)));
                        cfu_op0(1, a, i); 
						
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 0, 1, in_channel)));
                        cfu_op0(1, a, i); 
						
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 0, 2, in_channel)));
                        cfu_op0(1, a, i); 
						
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 1, 0, in_channel)));
                        cfu_op0(1, a, i); 
						
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 1, 1, in_channel)));
                        cfu_op0(1, a, i); 
						
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 1, 2, in_channel)));
                        cfu_op0(1, a, i); 
						
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 2, 0, in_channel)));
                        cfu_op0(1, a, i); 
						
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 2, 1, in_channel)));
                        cfu_op0(1, a, i); 
						
                        a = *((uint32_t *)(filter_data + Offset(filter_shape, out_channel + i, 2, 2, in_channel)));
                        cfu_op0(1, a, i); 
						
                        cfu_op0(1, 0, i);
                        cfu_op0(1, 0, i); 
                        cfu_op0(1, 0, i);  	    						
	       
                    }
                    // perf_disable_counter(0);        
                }             
            
                int32_t acc;      
                int id = 0; 
                
                // perf_enable_counter(0);
                
                
		// Storing the output activations 		
                for (int8_t i = 0; i < 4; i++){
                    for(int8_t j = 0; j < 4; j++){
                        for(int8_t k = 0; k < L; k++){
			  	
                            acc = cfu_op0(2, id, k);		
                            if (bias_data){
                                acc += bias_data[out_channel + k];
                            } 
                            acc = MultiplyByQuantizedMultiplier(acc, output_multiplier[out_channel + k], output_shift[out_channel + k]);
                            acc -= 128;
                            acc = std::max(acc, output_activation_min);
                            acc = std::min(acc, output_activation_max);
                            output_data[Offset(output_shape, 0, out_y + i, out_x + j, out_channel + k)] = static_cast<int8_t>(acc);
                        }
                        id += 1; 
                    }
                }
                
                // perf_disable_counter(0);
            }
        }
    }
  }		
}



// Fixed-point per-channel-quantization convolution reference kernel.
// 16-bit data and 8-bit filter
template <typename AccumScalar>
inline void ConvPerChannel(
    const ConvParams& params, const int32_t* output_multiplier,
    const int32_t* output_shift, const RuntimeShape& input_shape,
    const int16_t* input_data, const RuntimeShape& filter_shape,
    const int8_t* filter_data, const RuntimeShape& bias_shape,
    const AccumScalar* bias_data, const RuntimeShape& output_shape,
    int16_t* output_data) {
  // Get parameters.
  const int stride_width = params.stride_width;
  const int stride_height = params.stride_height;
  const int dilation_width_factor = params.dilation_width_factor;
  const int dilation_height_factor = params.dilation_height_factor;
  const int pad_width = params.padding_values.width;
  const int pad_height = params.padding_values.height;

  // Set min and max value of the output.
  const int32_t output_activation_min = params.quantized_activation_min;
  const int32_t output_activation_max = params.quantized_activation_max;

  // Consistency check.
  TFLITE_DCHECK_LE(output_activation_min, output_activation_max);
  TFLITE_DCHECK_EQ(input_shape.DimensionsCount(), 4);
  TFLITE_DCHECK_EQ(filter_shape.DimensionsCount(), 4);
  TFLITE_DCHECK_EQ(output_shape.DimensionsCount(), 4);
  const int batches = MatchingDim(input_shape, 0, output_shape, 0);
  const int input_depth = MatchingDim(input_shape, 3, filter_shape, 3);
  const int output_depth = MatchingDim(filter_shape, 0, output_shape, 3);
  if (bias_data) {
    TFLITE_DCHECK_EQ(bias_shape.FlatSize(), output_depth);
  }

  // Check dimensions of the tensors.
  const int input_height = input_shape.Dims(1);
  const int input_width = input_shape.Dims(2);
  const int filter_height = filter_shape.Dims(1);
  const int filter_width = filter_shape.Dims(2);
  const int output_height = output_shape.Dims(1);
  const int output_width = output_shape.Dims(2);
  
  for (int batch = 0; batch < batches; ++batch) {
    for (int out_y = 0; out_y < output_height; ++out_y) {
      const int in_y_origin = (out_y * stride_height) - pad_height;
      for (int out_x = 0; out_x < output_width; ++out_x) {
        const int in_x_origin = (out_x * stride_width) - pad_width;
        for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
          AccumScalar acc = 0;
          for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
            const int in_y = in_y_origin + dilation_height_factor * filter_y;
            for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
              const int in_x = in_x_origin + dilation_width_factor * filter_x;

              // Zero padding by omitting the areas outside the image.
              const bool is_point_inside_image =
                  (in_x >= 0) && (in_x < input_width) && (in_y >= 0) &&
                  (in_y < input_height);

              if (!is_point_inside_image) {
                continue;
              }

		
              for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                int32_t input_val = input_data[Offset(input_shape, batch, in_y,
                                                      in_x, in_channel)];
                int32_t filter_val = filter_data[Offset(
                    filter_shape, out_channel, filter_y, filter_x, in_channel)];
                // Accumulate with 64 bits accumulator.
                // int64_t += int8_t * int16_t so the highest value we can
                // get from each accumulation is [-127, 127] * ([-32768,
                // 32767] -
                // [-32768, 32767]), which is [-8322945, 8322945].
                // log2(8322945) = 22.99.
                acc += filter_val * input_val;
              }
            }
          }
          if (bias_data) {
            acc += bias_data[out_channel];
          }
          int32_t scaled_acc = MultiplyByQuantizedMultiplier(
              acc, output_multiplier[out_channel], output_shift[out_channel]);
          scaled_acc = std::max(scaled_acc, output_activation_min);
          scaled_acc = std::min(scaled_acc, output_activation_max);
          output_data[Offset(output_shape, batch, out_y, out_x, out_channel)] =
              static_cast<int16_t>(scaled_acc);
        }
      }
    }
  }
     
}

}  // namespace reference_integer_ops
}  // namespace tflite

#endif  // TENSORFLOW_LITE_KERNELS_INTERNAL_REFERENCE_INTEGER_OPS_CONV_H_


