@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalConsentFormTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalConsentFormTarget("code-886", title: "title-485")
        let view = Consent.toRegionalConsentFormTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalConsentFormTargetViews([item, item]).count == 2)
    }
}
