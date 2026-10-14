@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newFallbackRemittanceBundle("code-593", label: "label-338")
        let view = RevenueCycle.toFallbackRemittanceBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toFallbackRemittanceBundleViews([item, item]).count == 2)
    }
}
