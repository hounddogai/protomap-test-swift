@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyRoundingReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLegacyRoundingReservation("code-139", title: "title-353")
        let view = ClinicalOps.toLegacyRoundingReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLegacyRoundingReservationViews([item, item]).count == 2)
    }
}
