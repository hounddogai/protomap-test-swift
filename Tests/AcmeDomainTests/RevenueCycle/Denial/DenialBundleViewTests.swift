@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialBundle("code-659", name: "name-773")
        let view = RevenueCycle.toDenialBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialBundleViews([item, item]).count == 2)
    }
}
