@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledProxyProposal("code-142", label: "label-114")
        let view = Consent.toScheduledProxyProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledProxyProposalViews([item, item]).count == 2)
    }
}
