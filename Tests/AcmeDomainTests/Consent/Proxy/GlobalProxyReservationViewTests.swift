@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalProxyReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newGlobalProxyReservation("code-843", label: "label-736")
        let view = Consent.toGlobalProxyReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toGlobalProxyReservationViews([item, item]).count == 2)
    }
}
