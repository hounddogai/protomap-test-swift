@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalCleaningPlan("code-321", title: "title-582")
        let view = BedManagement.toGlobalCleaningPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalCleaningPlanViews([item, item]).count == 2)
    }
}
