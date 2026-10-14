@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialReservation("code-617", title: "title-500")
        let view = Staffing.toCredentialReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialReservationViews([item, item]).count == 2)
    }
}
