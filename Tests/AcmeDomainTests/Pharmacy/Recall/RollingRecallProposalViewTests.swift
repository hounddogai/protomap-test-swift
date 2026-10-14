@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingRecallProposal("code-146", label: "label-719")
        let view = Pharmacy.toRollingRecallProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingRecallProposalViews([item, item]).count == 2)
    }
}
