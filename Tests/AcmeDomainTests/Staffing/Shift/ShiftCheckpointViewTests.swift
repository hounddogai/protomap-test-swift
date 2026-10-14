@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftCheckpoint("code-16", label: "label-523")
        let view = Staffing.toShiftCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftCheckpointViews([item, item]).count == 2)
    }
}
