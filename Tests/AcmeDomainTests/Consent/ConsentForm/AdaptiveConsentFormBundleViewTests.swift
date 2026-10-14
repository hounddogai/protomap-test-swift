@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveConsentFormBundle("code-844", title: "title-457")
        let view = Consent.toAdaptiveConsentFormBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveConsentFormBundleViews([item, item]).count == 2)
    }
}
