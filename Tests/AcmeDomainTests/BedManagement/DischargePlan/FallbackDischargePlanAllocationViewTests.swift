@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackDischargePlanAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackDischargePlanAllocation("code-17", label: "label-258")
        let view = BedManagement.toFallbackDischargePlanAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackDischargePlanAllocationViews([item, item]).count == 2)
    }
}
