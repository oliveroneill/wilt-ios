import UIKit

/// The page view controller for onboarding
class OnboardingIntroViewController: UIPageViewController {
    private let pages: [UIViewController] = [
        OnboardingPage(
            text: "walkthrough1_text".localized,
            image: #imageLiteral(resourceName: "WalkthroughScreen1")
        ),
        OnboardingPage(
            text: "walkthrough2_text".localized,
            image: #imageLiteral(resourceName: "WalkthroughScreen2")
        ),
    ]

    convenience init() {
        self.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageControl()
        dataSource = self
        if let firstViewController = pages.first {
            setViewControllers(
                [firstViewController],
                direction: .forward,
                animated: true,
                completion: nil
            )
        }
    }

    private func setupPageControl() {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .darkGray
    }
}

extension OnboardingIntroViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = index - 1
        guard previousIndex >= 0, previousIndex < pages.count else {
            return nil
        }
        return pages[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }
        let nextIndex = index + 1
        guard nextIndex < pages.count else {
            return nil
        }
        return pages[nextIndex]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstPage = pages.first else {
            return 0
        }
        return pages.firstIndex(of: firstPage) ?? 0
    }
}
