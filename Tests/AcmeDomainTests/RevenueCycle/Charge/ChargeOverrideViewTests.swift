@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeOverride("code-64", name: "name-809")
        let view = RevenueCycle.toChargeOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeOverrideViews([item, item]).count == 2)
    }
}
