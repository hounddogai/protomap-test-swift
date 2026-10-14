@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientShiftSegment("code-340", title: "title-366")
        let view = Staffing.toLenientShiftSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientShiftSegmentViews([item, item]).count == 2)
    }
}
