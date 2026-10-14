@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledWitnessProposal("code-969", name: "name-440")
        let view = Consent.toScheduledWitnessProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledWitnessProposalViews([item, item]).count == 2)
    }
}
