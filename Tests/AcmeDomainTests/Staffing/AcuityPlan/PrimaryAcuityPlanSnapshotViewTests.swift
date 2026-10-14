@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryAcuityPlanSnapshot("code-883", label: "label-515")
        let view = Staffing.toPrimaryAcuityPlanSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryAcuityPlanSnapshotViews([item, item]).count == 2)
    }
}
