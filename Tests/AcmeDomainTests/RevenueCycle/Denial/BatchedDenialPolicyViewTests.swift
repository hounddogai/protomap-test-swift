@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedDenialPolicy("code-117", title: "title-693")
        let view = RevenueCycle.toBatchedDenialPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedDenialPolicyViews([item, item]).count == 2)
    }
}
