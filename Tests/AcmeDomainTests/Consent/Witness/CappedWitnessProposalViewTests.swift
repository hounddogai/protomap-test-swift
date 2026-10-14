@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedWitnessProposal("code-169", name: "name-586")
        let view = Consent.toCappedWitnessProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedWitnessProposalViews([item, item]).count == 2)
    }
}
