@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientShiftQuota("code-853", label: "label-183")
        let view = Staffing.toLenientShiftQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientShiftQuotaViews([item, item]).count == 2)
    }
}
