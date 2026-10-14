@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeProposal("code-964", name: "name-244")
        let view = Staffing.toOvertimeProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeProposalViews([item, item]).count == 2)
    }
}
