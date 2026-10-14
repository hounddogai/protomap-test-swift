@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledProxyDraft("code-855", name: "name-202")
        let view = Consent.toScheduledProxyDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledProxyDraftViews([item, item]).count == 2)
    }
}
