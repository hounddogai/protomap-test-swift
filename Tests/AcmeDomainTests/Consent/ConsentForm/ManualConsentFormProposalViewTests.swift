@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newManualConsentFormProposal("code-30", name: "name-732")
        let view = Consent.toManualConsentFormProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toManualConsentFormProposalViews([item, item]).count == 2)
    }
}
