@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftQuota("code-632", name: "name-274")
        let view = Staffing.toShiftQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftQuotaViews([item, item]).count == 2)
    }
}
