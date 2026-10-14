@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferPlan("code-258", title: "title-478")
        let view = BedManagement.toTransferPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferPlanViews([item, item]).count == 2)
    }
}
