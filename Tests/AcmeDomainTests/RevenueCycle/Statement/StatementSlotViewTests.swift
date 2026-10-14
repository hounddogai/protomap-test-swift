@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementSlot("code-712", label: "label-958")
        let view = RevenueCycle.toStatementSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementSlotViews([item, item]).count == 2)
    }
}
