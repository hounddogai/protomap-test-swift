@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimSlot("code-830", label: "label-754")
        let view = RevenueCycle.toClaimSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimSlotViews([item, item]).count == 2)
    }
}
