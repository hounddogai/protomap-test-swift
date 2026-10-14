@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyShiftRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLegacyShiftRollup("code-426", name: "name-55")
        let view = Staffing.toLegacyShiftRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLegacyShiftRollupViews([item, item]).count == 2)
    }
}
