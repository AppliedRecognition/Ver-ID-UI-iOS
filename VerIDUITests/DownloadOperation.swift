//
//  DownloadOperation.swift
//  VerIDUITests
//
//  Created by Jakub Dolejs on 21/10/2021.
//  Copyright © 2021 Applied Recognition. All rights reserved.
//

import Foundation
import UIKit
import VerIDCore

class DownloadOperation: Operation {
    
    let url: String
    var error: Error?
    var data: Data?
    private var _isExecuting: Bool = false
    private var _isFinished: Bool = false
    private var downloadTask: URLSessionDataTask?
    
    lazy var lockQueue = DispatchQueue(label: "download", qos: .default, attributes: .concurrent)
    
    override var isAsynchronous: Bool {
        true
    }
    
    override var isExecuting: Bool {
        get {
            return self.lockQueue.sync {
                return self._isExecuting
            }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            self.lockQueue.sync(flags: [.barrier]) {
                self._isExecuting = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isFinished: Bool {
        get {
            return self.lockQueue.sync {
                return self._isFinished
            }
        }
        set {
            willChangeValue(forKey: "isFinished")
            self.lockQueue.sync(flags: [.barrier]) {
                self._isFinished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }
    
    init(url: String) {
        self.url = url
    }
    
    override func start() {
        if isCancelled {
            self.finish()
        }
        self.isFinished = false
        self.isExecuting = true
        self.main()
    }
    
    override func main() {
        let session = URLSession(configuration: .ephemeral)
        guard let url = URL(string: self.url) else {
            self.error = TestingError(message: "Invalid URL: \(self.url)")
            return
        }
        self.downloadTask = session.dataTask(with: url) { data, response, error in
            if let err = error {
                self.error = err
            } else if let download = data {
                self.data = download
            } else {
                self.error = TestingError(message: "Download timed out")
            }
            self.finish()
        }
        if !self.isCancelled {
            self.downloadTask?.resume()
        }
    }
    
    override func cancel() {
        self.downloadTask?.cancel()
        super.cancel()
    }
    
    func finish() {
        self.isExecuting = false
        self.isFinished = true
    }
}

class ImageDownloadOperation: DownloadOperation {
    
    var image: UIImage?
    let user: String
    let index: Int
    
    init(url: String, user: String, index: Int) {
        self.user = user
        self.index = index
        super.init(url: url)
    }
    
    override func finish() {
        if let data = self.data, let image = UIImage(data: data) {
            self.image = image
        } else if self.error == nil {
            self.error = TestingError(message: "Failed to create image from downloaded data")
        }
        super.finish()
    }
}

class FaceDownloadOperation: DownloadOperation {
    
    var face: RecognizableFace?
    let user: String
    let index: Int
    
    init(url: String, user: String, index: Int) {
        self.user = user
        self.index = index
        super.init(url: url)
    }
    
    override func finish() {
        if let data = self.data {
            do {
                self.face = try JSONDecoder().decode(RecognizableFace.self, from: data)
            } catch {
                self.error = error
            }
        }
        super.finish()
    }
}
