@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementPreference("code-482", name: "name-888")
        let view = RevenueCycle.toStatementPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementPreferenceViews([item, item]).count == 2)
    }
}
