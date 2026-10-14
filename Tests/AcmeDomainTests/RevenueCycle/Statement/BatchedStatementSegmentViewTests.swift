@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedStatementSegment("code-521", name: "name-198")
        let view = RevenueCycle.toBatchedStatementSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedStatementSegmentViews([item, item]).count == 2)
    }
}
