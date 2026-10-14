@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalRecallProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalRecallProposal("code-558", name: "name-870")
        let view = Pharmacy.toRegionalRecallProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalRecallProposalViews([item, item]).count == 2)
    }
}
