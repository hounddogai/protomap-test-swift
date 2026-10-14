@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictProxyBudget("code-904", title: "title-917")
        let view = Consent.toStrictProxyBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictProxyBudgetViews([item, item]).count == 2)
    }
}
