@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackShiftBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackShiftBaseline("code-671", name: "name-271")
        let view = Staffing.toFallbackShiftBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackShiftBaselineViews([item, item]).count == 2)
    }
}
