@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newManualOvertimeProposal("code-5", name: "name-232")
        let view = Staffing.toManualOvertimeProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toManualOvertimeProposalViews([item, item]).count == 2)
    }
}
