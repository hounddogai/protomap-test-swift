@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredShiftSummary("code-464", title: "title-798")
        let view = Staffing.toTieredShiftSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredShiftSummaryViews([item, item]).count == 2)
    }
}
