@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementEntry("code-410", name: "name-815")
        let view = RevenueCycle.toStatementEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementEntryViews([item, item]).count == 2)
    }
}
