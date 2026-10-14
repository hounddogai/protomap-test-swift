@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingDisclosureBudget("code-928", label: "label-645")
        let view = Consent.toRollingDisclosureBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingDisclosureBudgetViews([item, item]).count == 2)
    }
}
