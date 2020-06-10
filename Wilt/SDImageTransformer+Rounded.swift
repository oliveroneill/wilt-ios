import SDWebImage

enum SDImageTransformers {
    static var roundCornerTransformer: SDImageTransformer = {
        return SDImagePipelineTransformer(
            transformers: [
                SDImageCroppingTransformer(
                    rect: CGRect(
                        origin: .zero,
                        // Fix the height and width since the images out of
                        // Spotify aren't consistent sizes
                        size: CGSize(width: 640, height: 640)
                    )
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
