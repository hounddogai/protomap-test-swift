@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedStatementGroup("code-987", title: "title-697")
        let view = RevenueCycle.toBatchedStatementGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedStatementGroupViews([item, item]).count == 2)
    }
}
