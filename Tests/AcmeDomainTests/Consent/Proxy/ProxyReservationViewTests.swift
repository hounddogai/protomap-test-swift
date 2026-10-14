@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyReservation("code-761", name: "name-273")
        let view = Consent.toProxyReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyReservationViews([item, item]).count == 2)
    }
}
