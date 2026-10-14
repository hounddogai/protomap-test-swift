@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalOvertimeEntry("code-850", name: "name-607")
        let view = Staffing.toRegionalOvertimeEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalOvertimeEntryViews([item, item]).count == 2)
    }
}
