@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualDischargePlanVariance("code-531", label: "label-620")
        let view = BedManagement.toManualDischargePlanVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualDischargePlanVarianceViews([item, item]).count == 2)
    }
}
