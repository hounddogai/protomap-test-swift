@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftSegment("code-969", label: "label-856")
        let view = Staffing.toShiftSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftSegmentViews([item, item]).count == 2)
    }
}
