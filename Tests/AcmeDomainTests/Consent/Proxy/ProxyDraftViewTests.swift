@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyDraft("code-696", name: "name-577")
        let view = Consent.toProxyDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyDraftViews([item, item]).count == 2)
    }
}
