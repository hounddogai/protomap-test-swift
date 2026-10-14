@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeCheckpoint("code-394", label: "label-714")
        let view = Staffing.toOvertimeCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeCheckpointViews([item, item]).count == 2)
    }
}
