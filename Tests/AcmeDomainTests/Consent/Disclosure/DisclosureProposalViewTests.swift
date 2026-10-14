@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureProposal("code-453", label: "label-771")
        let view = Consent.toDisclosureProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureProposalViews([item, item]).count == 2)
    }
}
