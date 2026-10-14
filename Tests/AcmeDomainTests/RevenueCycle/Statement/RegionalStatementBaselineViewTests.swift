@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalStatementBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalStatementBaseline("code-544", label: "label-902")
        let view = RevenueCycle.toRegionalStatementBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalStatementBaselineViews([item, item]).count == 2)
    }
}
