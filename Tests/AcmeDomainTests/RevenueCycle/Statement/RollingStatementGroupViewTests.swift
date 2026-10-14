@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingStatementGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingStatementGroup("code-466", title: "title-299")
        let view = RevenueCycle.toRollingStatementGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingStatementGroupViews([item, item]).count == 2)
    }
}
