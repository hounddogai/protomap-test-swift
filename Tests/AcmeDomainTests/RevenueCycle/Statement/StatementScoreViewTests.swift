@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementScore("code-910", label: "label-947")
        let view = RevenueCycle.toStatementScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementScoreViews([item, item]).count == 2)
    }
}
