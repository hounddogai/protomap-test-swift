@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguageBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newFallbackLanguageBudget("code-294", title: "title-691")
        let view = Consent.toFallbackLanguageBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toFallbackLanguageBudgetViews([item, item]).count == 2)
    }
}
