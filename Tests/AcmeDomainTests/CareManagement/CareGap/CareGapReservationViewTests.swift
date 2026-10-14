@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapReservation("code-667", name: "name-614")
        let view = CareManagement.toCareGapReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapReservationViews([item, item]).count == 2)
    }
}
