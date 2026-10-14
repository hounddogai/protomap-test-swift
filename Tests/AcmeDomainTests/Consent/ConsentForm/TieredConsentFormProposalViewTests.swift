@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredConsentFormProposal("code-149", label: "label-272")
        let view = Consent.toTieredConsentFormProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredConsentFormProposalViews([item, item]).count == 2)
    }
}
