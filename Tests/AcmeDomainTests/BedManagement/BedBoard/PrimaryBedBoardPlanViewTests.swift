@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryBedBoardPlan("code-628", name: "name-689")
        let view = BedManagement.toPrimaryBedBoardPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryBedBoardPlanViews([item, item]).count == 2)
    }
}
