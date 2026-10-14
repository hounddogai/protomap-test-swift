@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedClaimReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newCappedClaimReservation("code-648", label: "label-312")
        let view = RevenueCycle.toCappedClaimReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toCappedClaimReservationViews([item, item]).count == 2)
    }
}
