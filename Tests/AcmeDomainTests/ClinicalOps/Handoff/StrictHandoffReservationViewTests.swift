@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictHandoffReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newStrictHandoffReservation("code-647", label: "label-646")
        let view = ClinicalOps.toStrictHandoffReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toStrictHandoffReservationViews([item, item]).count == 2)
    }
}
