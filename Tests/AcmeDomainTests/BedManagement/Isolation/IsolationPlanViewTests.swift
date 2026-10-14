@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationPlan("code-794", label: "label-111")
        let view = BedManagement.toIsolationPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationPlanViews([item, item]).count == 2)
    }
}
