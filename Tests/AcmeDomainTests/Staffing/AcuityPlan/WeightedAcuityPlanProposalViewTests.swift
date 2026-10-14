@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedAcuityPlanProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newWeightedAcuityPlanProposal("code-691", label: "label-180")
        let view = Staffing.toWeightedAcuityPlanProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toWeightedAcuityPlanProposalViews([item, item]).count == 2)
    }
}
