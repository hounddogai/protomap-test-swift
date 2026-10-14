@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultConsentFormAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultConsentFormAdjustment("code-736", title: "title-403")
        let view = Consent.toDefaultConsentFormAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultConsentFormAdjustmentViews([item, item]).count == 2)
    }
}
