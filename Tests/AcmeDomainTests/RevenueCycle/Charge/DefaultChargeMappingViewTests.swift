@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDefaultChargeMapping("code-504", label: "label-791")
        let view = RevenueCycle.toDefaultChargeMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDefaultChargeMappingViews([item, item]).count == 2)
    }
}
