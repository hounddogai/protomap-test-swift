@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLenientRemittanceSlot("code-452", title: "title-731")
        let view = RevenueCycle.toLenientRemittanceSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLenientRemittanceSlotViews([item, item]).count == 2)
    }
}
