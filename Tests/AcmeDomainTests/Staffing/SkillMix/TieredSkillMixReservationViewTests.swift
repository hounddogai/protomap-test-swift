@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredSkillMixReservation("code-172", title: "title-874")
        let view = Staffing.toTieredSkillMixReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredSkillMixReservationViews([item, item]).count == 2)
    }
}
