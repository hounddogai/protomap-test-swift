@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementMapping("code-159", title: "title-945")
        let view = RevenueCycle.toStatementMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementMappingViews([item, item]).count == 2)
    }
}
