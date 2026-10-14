@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalStatementAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newSeasonalStatementAgreement("code-866", name: "name-728")
        let view = RevenueCycle.toSeasonalStatementAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toSeasonalStatementAgreementViews([item, item]).count == 2)
    }
}
