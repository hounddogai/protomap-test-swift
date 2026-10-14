@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientProxyBudget("code-778", label: "label-438")
        let view = Consent.toLenientProxyBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientProxyBudgetViews([item, item]).count == 2)
    }
}
