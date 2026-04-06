import UIKit
import SwiftUI

/// Hosts the SwiftUI ActionView inside the Action Extension sheet.
/// Mirrors the pattern used in ReplAIShareExtension/ShareViewController.swift.
final class ActionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let actionView = ActionView(context: extensionContext)
        let host = UIHostingController(rootView: actionView)

        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        host.didMove(toParent: self)
    }
}
