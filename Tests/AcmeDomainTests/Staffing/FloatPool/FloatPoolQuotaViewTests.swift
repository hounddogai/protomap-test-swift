@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolQuota("code-771", label: "label-192")
        let view = Staffing.toFloatPoolQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolQuotaViews([item, item]).count == 2)
    }
}
