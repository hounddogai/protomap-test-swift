@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementSummary("code-527", name: "name-595")
        let view = RevenueCycle.toStatementSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementSummaryViews([item, item]).count == 2)
    }
}
