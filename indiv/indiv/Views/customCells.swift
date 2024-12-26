import UIKit

class CustomModelCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descLabel: UILabel!
    @IBOutlet var bgImageCellView: UIImageView!
    @IBOutlet var cellView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellView.layer.cornerRadius = 10
        cellView.layer.masksToBounds = true
        bgImageCellView.layer.cornerRadius = 10
        bgImageCellView.layer.masksToBounds = true
        //applyGradientToImageView(imageView: bgImageCellView)
        
    }
    
    func applyGradientToImageView(imageView: UIImageView) {
        // Создаем слой для градиента
        let gradientLayer = CAGradientLayer()
        
        // Настроим размер слоя градиента, он должен совпадать с размером изображения
        gradientLayer.frame = imageView.bounds
        
        gradientLayer.colors = [
            tintColor.withAlphaComponent(1).cgColor,  // Градиент от голубовато-синего
            tintColor.withAlphaComponent(0.3).cgColor,  // Плавный переход
            tintColor.withAlphaComponent(0.0).cgColor,  // Еще более прозрачный синий
            UIColor.clear.cgColor  // И, наконец, прозрачность
        ]
        
        // Настроим позиции для цветов
        gradientLayer.locations = [0.0, 0.1, 0.2, 1.0]  // Позиции плавного перехода от синего к прозрачному
        
        // Направление градиента - от левого края к правому
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)  // Левый край
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)    // Правый край
                
        
        // Добавляем градиентный слой как подслой на слой UIImageView
        imageView.layer.addSublayer(gradientLayer)
    }
}

class CustomApiModelCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descLabel: UILabel!
    @IBOutlet var bgImageSellView: UIImageView!
    @IBOutlet var downloadButton: UIButton!
    @IBOutlet var cellView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellView.layer.cornerRadius = 10
        cellView.layer.masksToBounds = true
        bgImageSellView.layer.cornerRadius = 10
        bgImageSellView.layer.masksToBounds = true
        applyGradientToImageView(imageView: bgImageSellView)
        
    }
    
    func applyGradientToImageView(imageView: UIImageView) {
        // Создаем слой для градиента
        let gradientLayer = CAGradientLayer()
        
        // Настроим размер слоя градиента, он должен совпадать с размером изображения
        gradientLayer.frame = imageView.bounds
        
        gradientLayer.colors = [
            UIColor.systemPink.withAlphaComponent(1).cgColor,  // Градиент от голубовато-синего
            UIColor.systemPink.withAlphaComponent(0.3).cgColor,  // Плавный переход
            UIColor.systemPink.withAlphaComponent(0.0).cgColor,  // Еще более прозрачный синий
            UIColor.clear.cgColor  // И, наконец, прозрачность
        ]
        
        // Настроим позиции для цветов
        gradientLayer.locations = [0.0, 0.1, 0.2, 1.0]  // Позиции плавного перехода от синего к прозрачному
        
        // Направление градиента - от левого края к правому
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)  // Левый край
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)    // Правый край
                
        
        // Добавляем градиентный слой как подслой на слой UIImageView
        imageView.layer.addSublayer(gradientLayer)
    }
}
