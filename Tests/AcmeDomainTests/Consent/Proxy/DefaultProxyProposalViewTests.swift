@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultProxyProposal("code-503", label: "label-460")
        let view = Consent.toDefaultProxyProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultProxyProposalViews([item, item]).count == 2)
    }
}
