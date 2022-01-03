//
//  ViewController.swift
//  QuickEasyAsyncAwait
//
//  Created by Michael Vo on 1/1/22.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var photoContainerViewTop: UIView!
    @IBOutlet weak var photoContainerViewBottom: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        
        guard let url = URL(string: "https://upload.wikimedia.org/wikipedia/en/f/f7/RickRoll.png") else { return }
        let request = URLRequest(url: url)
        
        /// Call site 1.
        /// Get the image via the classic way.
        getImageDataTheOldWay(request) { (i: UIImage?, e: Error?) in
            if e != nil { return }
            if let image = i {
                self.setImage(image, self.photoContainerViewTop)
            }
        }
        
        /// Call site 2.
        /// Get the image via the async await method.
        Task {
            let image = try await getImageDataViaTheAsyncAwaitWay(request)
            setImage(image, photoContainerViewBottom)
        }
    }

    /**
     This method allows for a completion handler to be called that will return an image or an error.
     - parameter url: The URLRequest that contains the URL where the image is.
     - parameter completionHandler: The completion handler that will return either an image or an error.
     */
    func getImageDataTheOldWay(_ url: URLRequest, completionHandler: @escaping (UIImage?, Error?) -> Void) -> Void {
        /// Call the classic URLSession data task. (The non async await version).
        let session = URLSession.shared.dataTask(with: url) { (d: Data?, r: URLResponse?, e: Error?) in
            /// If the error parameter is not nil, we have an error and need to call the completion handler with the error.
            if e != nil {
                completionHandler(nil, CustomError.GENERIC_ERROR)
                return
            }
            
            /// Check if the response has a status code of 200 "OK"
            if let response = r as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let d = d {
                        /// Now try to take the data and turn it into a UIImage.
                        if let image = UIImage(data: d) {
                            /// All is good, call the completion handler returning the image.
                            completionHandler(image, nil)
                            return
                        } else {
                            /// The data failed to generate a UIImage. Call the completion handler with a Bad Data error.
                            completionHandler(nil, CustomError.BAD_DATA)
                            return
                        }
                    } else {
                        /// The data failed to generate a UIImage. Call the completion handler with a Bad Data error.
                        completionHandler(nil, CustomError.BAD_DATA)
                        return
                    }
                } else {
                    /// The response code was something other than 200. Call the completion handler with a Bad Status Code error.
                    completionHandler(nil, CustomError.BAD_STATUS_CODE)
                    return
                }
            }
            /// We did not get a HTTPResponse as expected. Call the completion handler with a Generic error.
            completionHandler(nil, CustomError.GENERIC_ERROR)
            return
        }
        session.resume()
    }

    /**
     This method gets an image from a url request using the modern async await technique.
     - parameter url: This is the URL Request that contains the URL to the image.
     - returns: A UIImage that can be placed in a UIImageView.
     - throws: A CustomError indicating what happened.
     */
    func getImageDataViaTheAsyncAwaitWay(_ url: URLRequest) async throws -> UIImage {
        /// Call the async await version of the URLSession shared data function.
        let (data, response) = try await URLSession.shared.data(for: url)
        
        /// Check if the response has a status code of 200 "OK"
        if (response as? HTTPURLResponse)?.statusCode == 200 {
            /// Now try to take the data and turn it into a UIImage.
            if let image = UIImage(data: data) {
                /// All is good, return the image to be dipslayed in the UI.
                return image
            } else {
                throw CustomError.BAD_DATA
            }
        } else {
            throw CustomError.BAD_STATUS_CODE
        }
    }
    
    /**
     Put the downloaded image into its container view
     - parameter image: The UIImage that was downlaoded from a URL
     - parameter container: The container view that will house the image.
     */
    func setImage(_ image: UIImage, _ container: UIView) {
        DispatchQueue.main.async {
            let imageView = UIImageView.init(frame: self.photoContainerViewTop.bounds)
            imageView.image = image
            container.addSubview(imageView)
            container.contentMode = .scaleAspectFit
        }
        
    }
}

enum CustomError: String, Error {
    case BAD_STATUS_CODE = "Bad status code."
    case BAD_DATA = "Bad data, it could not be turned into an image."
    case GENERIC_ERROR = "Generic error."
}
