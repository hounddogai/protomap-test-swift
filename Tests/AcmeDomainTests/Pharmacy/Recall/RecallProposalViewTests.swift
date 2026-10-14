@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallProposal("code-335", label: "label-761")
        let view = Pharmacy.toRecallProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallProposalViews([item, item]).count == 2)
    }
}
