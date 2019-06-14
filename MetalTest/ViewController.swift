//
//  ViewController.swift
//  MetalTest
//
//  Created by isec on 2019/6/13.
//  Copyright © 2019 huangrui. All rights reserved.
//

import UIKit
import Metal


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 获取一个GPU对象
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        // 该方法会读取 bundle 中所有 .metal 文件
        guard let library = device.makeDefaultLibrary() else { return }
        
        // 获取对应的 GPU 函数（shader），此处获取 add_arrays 函数
        guard let addFunction = library.makeFunction(name: "add_arrays") else { return }
        
        do {
            // 创建一个 pipeline （管道），通过它，你将 Metal 函数转换成GPU可执行编码，同时，它也指定了 GPU 完成对应任务的步数 L.55 ~ L.61
            let pipelineState = try device.makeComputePipelineState(function: addFunction)
            
            // 通过 CommandQueue 将需要完成的任务发送给 GPU
            guard let commandQueue = device.makeCommandQueue() else { return }
            
            // 创建 MTLBuffer 对象来保存输入与输出参数
            let size = MemoryLayout<Int>.stride
            let count = 5
            let length = size * count
            
            let listA = [1, 2, 3, 4, 5]
            guard let buffA = device.makeBuffer(bytes: listA, length: length, options: .storageModeShared) else { return }
            
            let listB = [2, 3, 4, 5, 6]
            guard let buffB = device.makeBuffer(bytes: listB, length: length, options: .storageModeShared) else { return }
            
            guard let buffC = device.makeBuffer(length: length, options: .storageModeShared) else { return }

            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            
            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            commandEncoder.setComputePipelineState(pipelineState)
            commandEncoder.setBuffer(buffA, offset: 0, index: 0)
            commandEncoder.setBuffer(buffB, offset: 0, index: 1)
            commandEncoder.setBuffer(buffC, offset: 0, index: 2)
            
            // 因为 GPU 计算是并行的，需要确定计算的“步数”，即执行一次，计算多少组数组
            let gridSize = MTLSize(width: length, height: 1, depth: 1)
            var threadGroupSize = pipelineState.maxTotalThreadsPerThreadgroup
            if threadGroupSize > count {
                threadGroupSize = count
            }
            let threadgroupSize = MTLSize(width: threadGroupSize, height: 1, depth: 1)
            
            commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
            commandEncoder.endEncoding()
            
            // 即算完成回调，必须放在 commit() 方法前
            commandBuffer.addCompletedHandler { (buffer) in
                print("calculate complete!")
                let ptrA = buffA.contents()
                let ptrB = buffB.contents()
                let ptrC = buffC.contents()
                
                for i in 0..<5 {
                    let size = MemoryLayout<Int>.size
                    let type = Int.self
                    let a = ptrA.load(fromByteOffset: size * i, as: type)
                    let b = ptrB.load(fromByteOffset: size * i, as: type)
                    let c = ptrC.load(fromByteOffset: size * i, as: type)
                    print("a = \(a), b = \(b), c = \(c)")
                }
            }
            
            // 提交计算任务给 GPU
            commandBuffer.commit()
            
        } catch {
            print("error = \(error)")
        }
    }


}

