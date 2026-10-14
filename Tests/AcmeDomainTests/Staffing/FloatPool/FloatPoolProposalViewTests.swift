@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolProposal("code-119", title: "title-735")
        let view = Staffing.toFloatPoolProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolProposalViews([item, item]).count == 2)
    }
}
