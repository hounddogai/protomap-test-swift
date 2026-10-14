@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementGroup("code-112", title: "title-966")
        let view = RevenueCycle.toStatementGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementGroupViews([item, item]).count == 2)
    }
}
