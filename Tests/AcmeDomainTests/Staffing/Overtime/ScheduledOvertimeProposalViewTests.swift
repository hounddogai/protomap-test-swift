@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledOvertimeProposal("code-498", label: "label-785")
        let view = Staffing.toScheduledOvertimeProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledOvertimeProposalViews([item, item]).count == 2)
    }
}
