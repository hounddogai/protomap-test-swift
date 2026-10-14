@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualAuthorizationRollup("code-195", label: "label-947")
        let view = RevenueCycle.toManualAuthorizationRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualAuthorizationRollupViews([item, item]).count == 2)
    }
}
