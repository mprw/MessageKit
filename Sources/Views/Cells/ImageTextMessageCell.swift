/*
 MIT License
 
 Copyright (c) 2017-2018 MessageKit
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

open class ImageTextMessageCell: MessageCollectionViewCell {
    
    open override class func reuseIdentifier() -> String { return "messagekit.cell.imagetext" }
    
    // MARK: - Properties
    
    open override weak var delegate: MessageCellDelegate? {
        didSet {
            messageLabel.delegate = delegate
        }
    }
    
    open var imageView = UIImageView()
    
    open var messageLabel = MessageLabel()
    
    open var richContentView = UIView()
    
    open var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    // MARK: - Methods
    
    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            messageLabel.textInsets = attributes.messageLabelInsets
            messageLabel.font = attributes.messageLabelFont
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.attributedText = nil
        messageLabel.text = nil
    }
    
    open func setupConstraints() {
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        richContentView.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel.heightAnchor.constraint(equalToConstant: 32).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: richContentView.rightAnchor).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: richContentView.leftAnchor).isActive = true
        messageLabel.bottomAnchor.constraint(equalTo: richContentView.bottomAnchor).isActive = true
        
        imageView.fillSuperview()
        richContentView.fillSuperview()
        activityIndicator.centerInSuperview()
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        
        messageLabel.numberOfLines = 1
        messageLabel.lineBreakMode = .byTruncatingTail
        
        imageView.addSubview(messageLabel)
        richContentView.addSubview(imageView)
        richContentView.addSubview(activityIndicator)
        messageContainerView.addSubview(richContentView)
        
        imageView.contentMode = .scaleAspectFill
        
        setupConstraints()
    }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }
        
        let textColor = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView)
        let enabledDetectors = displayDelegate.enabledDetectors(for: message, at: indexPath, in: messagesCollectionView)
        let animationBlock = displayDelegate.animationBlockForLocation(message: message, at: indexPath, in: messagesCollectionView)

        activityIndicator.startAnimating()

        messageLabel.configure {
            messageLabel.enabledDetectors = enabledDetectors
            for detector in enabledDetectors {
                let attributes = displayDelegate.detectorAttributes(for: detector, and: message, at: indexPath)
                messageLabel.setAttributes(attributes, detector: detector)
            }
            switch message.data {
            case .imageText(let text, let image):
                imageView.image = image
                messageLabel.text = text
            case .shareImage(let text, _, let imageUrl):
                messageLabel.text = text
                let request = URLRequest(url: imageUrl)
                let session = URLSession.shared

                let dataTask = session.dataTask(with: request) { [weak self] (data: Data?, _, _) -> Void in
                    guard let strongSelf = self else { return }
                    DispatchQueue.main.async {
                        if let imageData = data as Data? {
                            strongSelf.imageView.image = UIImage(data: imageData)
                            strongSelf.activityIndicator.stopAnimating()
                            animationBlock?(strongSelf.imageView)
                        }
                    }
                }
                dataTask.resume()
                
            default:
                break
            }
            // Needs to be set after the attributedText because it takes precedence
            messageLabel.textColor = textColor
        }
    }
}
