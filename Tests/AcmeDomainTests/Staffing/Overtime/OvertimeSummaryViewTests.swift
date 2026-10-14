@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeSummary("code-148", title: "title-166")
        let view = Staffing.toOvertimeSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeSummaryViews([item, item]).count == 2)
    }
}
