@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeProfile("code-930", label: "label-402")
        let view = RevenueCycle.toChargeProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeProfileViews([item, item]).count == 2)
    }
}
