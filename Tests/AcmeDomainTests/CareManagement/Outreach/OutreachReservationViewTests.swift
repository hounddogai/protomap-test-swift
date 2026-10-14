@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachReservation("code-382", label: "label-314")
        let view = CareManagement.toOutreachReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachReservationViews([item, item]).count == 2)
    }
}
