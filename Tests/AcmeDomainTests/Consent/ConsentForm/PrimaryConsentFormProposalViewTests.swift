@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryConsentFormProposal("code-152", name: "name-114")
        let view = Consent.toPrimaryConsentFormProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryConsentFormProposalViews([item, item]).count == 2)
    }
}
