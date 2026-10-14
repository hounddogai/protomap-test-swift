@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyProxyTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLegacyProxyTemplate("code-456", title: "title-844")
        let view = Consent.toLegacyProxyTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLegacyProxyTemplateViews([item, item]).count == 2)
    }
}
