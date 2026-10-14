@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newBatchedOvertimeEntry("code-272", title: "title-482")
        let view = Staffing.toBatchedOvertimeEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toBatchedOvertimeEntryViews([item, item]).count == 2)
    }
}
