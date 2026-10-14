@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedShiftSnapshot("code-87", label: "label-771")
        let view = Staffing.toCappedShiftSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedShiftSnapshotViews([item, item]).count == 2)
    }
}
