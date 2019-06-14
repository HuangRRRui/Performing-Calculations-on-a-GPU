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
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        guard let library = device.makeDefaultLibrary() else { return }
        
        guard let addFunction = library.makeFunction(name: "add_arrays") else { return }
        
        do {
            let pipelineState = try device.makeComputePipelineState(function: addFunction)
            
            guard let commandQueue = device.makeCommandQueue() else { return }
            
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
            
            let gridSize = MTLSize(width: length, height: 1, depth: 1)
            var threadGroupSize = pipelineState.maxTotalThreadsPerThreadgroup
            if threadGroupSize > count {
                threadGroupSize = count
            }
            let threadgroupSize = MTLSize(width: threadGroupSize, height: 1, depth: 1)
            
            commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
            commandEncoder.endEncoding()
            
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
            
            commandBuffer.commit()
            
        } catch {
            print("error = \(error)")
        }
    }


}

