@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimReservation("code-370", label: "label-323")
        let view = RevenueCycle.toClaimReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimReservationViews([item, item]).count == 2)
    }
}
