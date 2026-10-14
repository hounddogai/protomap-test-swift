@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftVariance("code-277", title: "title-928")
        let view = Staffing.toShiftVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftVarianceViews([item, item]).count == 2)
    }
}
