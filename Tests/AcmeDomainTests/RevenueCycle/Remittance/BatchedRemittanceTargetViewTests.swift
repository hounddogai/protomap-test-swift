@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedRemittanceTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedRemittanceTarget("code-120", title: "title-620")
        let view = RevenueCycle.toBatchedRemittanceTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedRemittanceTargetViews([item, item]).count == 2)
    }
}
