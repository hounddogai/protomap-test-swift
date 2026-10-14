@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredOvertimeProposal("code-323", name: "name-841")
        let view = Staffing.toTieredOvertimeProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredOvertimeProposalViews([item, item]).count == 2)
    }
}
