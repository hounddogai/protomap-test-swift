@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalDisclosureBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalDisclosureBudget("code-777", title: "title-954")
        let view = Consent.toRegionalDisclosureBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalDisclosureBudgetViews([item, item]).count == 2)
    }
}
