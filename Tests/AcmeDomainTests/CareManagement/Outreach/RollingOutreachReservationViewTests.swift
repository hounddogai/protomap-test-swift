@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingOutreachReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingOutreachReservation("code-720", label: "label-588")
        let view = CareManagement.toRollingOutreachReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingOutreachReservationViews([item, item]).count == 2)
    }
}
