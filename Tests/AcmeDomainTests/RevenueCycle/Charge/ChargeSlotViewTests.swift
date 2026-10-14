@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeSlot("code-510", label: "label-524")
        let view = RevenueCycle.toChargeSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeSlotViews([item, item]).count == 2)
    }
}
