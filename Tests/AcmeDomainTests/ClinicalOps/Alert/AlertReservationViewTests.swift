@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertReservation("code-506", title: "title-679")
        let view = ClinicalOps.toAlertReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertReservationViews([item, item]).count == 2)
    }
}
