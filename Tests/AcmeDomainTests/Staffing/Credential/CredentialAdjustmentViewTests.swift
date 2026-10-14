@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialAdjustment("code-782", name: "name-942")
        let view = Staffing.toCredentialAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialAdjustmentViews([item, item]).count == 2)
    }
}
