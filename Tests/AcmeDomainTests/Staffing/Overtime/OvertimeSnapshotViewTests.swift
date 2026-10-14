@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeSnapshot("code-409", label: "label-115")
        let view = Staffing.toOvertimeSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeSnapshotViews([item, item]).count == 2)
    }
}
