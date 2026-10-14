@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyProxyBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLegacyProxyBudget("code-822", title: "title-696")
        let view = Consent.toLegacyProxyBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLegacyProxyBudgetViews([item, item]).count == 2)
    }
}
