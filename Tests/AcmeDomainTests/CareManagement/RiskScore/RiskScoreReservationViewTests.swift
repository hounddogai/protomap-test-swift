@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRiskScoreReservation("code-503", title: "title-472")
        let view = CareManagement.toRiskScoreReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRiskScoreReservationViews([item, item]).count == 2)
    }
}
