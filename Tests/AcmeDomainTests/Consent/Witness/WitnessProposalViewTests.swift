@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessProposal("code-459", title: "title-825")
        let view = Consent.toWitnessProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessProposalViews([item, item]).count == 2)
    }
}
