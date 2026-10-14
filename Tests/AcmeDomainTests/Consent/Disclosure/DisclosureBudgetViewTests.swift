@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureBudget("code-817", title: "title-228")
        let view = Consent.toDisclosureBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureBudgetViews([item, item]).count == 2)
    }
}
