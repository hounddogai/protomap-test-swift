@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newWeightedChargePolicy("code-50", label: "label-680")
        let view = RevenueCycle.toWeightedChargePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toWeightedChargePolicyViews([item, item]).count == 2)
    }
}
