@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningPlan("code-92", title: "title-536")
        let view = BedManagement.toCleaningPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningPlanViews([item, item]).count == 2)
    }
}
