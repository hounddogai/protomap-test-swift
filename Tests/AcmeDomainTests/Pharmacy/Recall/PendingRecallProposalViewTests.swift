@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingRecallProposal("code-62", title: "title-131")
        let view = Pharmacy.toPendingRecallProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingRecallProposalViews([item, item]).count == 2)
    }
}
