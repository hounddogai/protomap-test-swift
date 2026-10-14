@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedProxyProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedProxyProposal("code-883", name: "name-331")
        let view = Consent.toCappedProxyProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedProxyProposalViews([item, item]).count == 2)
    }
}
