@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDischargePlanEstimate("code-147", label: "label-277")
        let view = BedManagement.toDischargePlanEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDischargePlanEstimateViews([item, item]).count == 2)
    }
}
