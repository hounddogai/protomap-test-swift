@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeBatch("code-578", name: "name-100")
        let view = Staffing.toOvertimeBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeBatchViews([item, item]).count == 2)
    }
}
