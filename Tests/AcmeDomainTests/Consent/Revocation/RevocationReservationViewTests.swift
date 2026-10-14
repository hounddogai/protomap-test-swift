@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationReservation("code-221", label: "label-523")
        let view = Consent.toRevocationReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationReservationViews([item, item]).count == 2)
    }
}
