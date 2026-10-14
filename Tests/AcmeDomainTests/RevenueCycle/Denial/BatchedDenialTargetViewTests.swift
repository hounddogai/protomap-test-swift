@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedDenialTarget("code-42", name: "name-739")
        let view = RevenueCycle.toBatchedDenialTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedDenialTargetViews([item, item]).count == 2)
    }
}
