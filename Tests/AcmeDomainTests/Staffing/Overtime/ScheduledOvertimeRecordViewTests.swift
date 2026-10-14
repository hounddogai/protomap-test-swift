@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledOvertimeRecord("code-971", label: "label-899")
        let view = Staffing.toScheduledOvertimeRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledOvertimeRecordViews([item, item]).count == 2)
    }
}
