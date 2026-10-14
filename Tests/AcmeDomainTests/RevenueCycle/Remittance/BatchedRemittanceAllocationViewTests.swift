@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedRemittanceAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedRemittanceAllocation("code-750", label: "label-742")
        let view = RevenueCycle.toBatchedRemittanceAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedRemittanceAllocationViews([item, item]).count == 2)
    }
}
