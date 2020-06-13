import SDWebImage

enum SDImageTransformers {
    static var roundCornerTransformer: SDImageTransformer = {
        return SDImagePipelineTransformer(
            transformers: [
                SDImageResizingTransformer(
                    size: CGSize(width: 100, height: 100),
                    scaleMode: .aspectFill
                ),
                SDImageRoundCornerTransformer(
                    // This will ensure that the image comes out as a circle
                    radius: CGFloat.greatestFiniteMagnitude,
                    corners: .allCorners,
                    borderWidth: 0,
                    borderColor: nil
                )
            ]
        )
    }()
}
