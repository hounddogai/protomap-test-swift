@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackTransferPlan("code-78", label: "label-944")
        let view = BedManagement.toFallbackTransferPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackTransferPlanViews([item, item]).count == 2)
    }
}
