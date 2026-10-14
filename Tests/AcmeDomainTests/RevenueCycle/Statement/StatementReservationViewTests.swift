@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementReservation("code-603", title: "title-206")
        let view = RevenueCycle.toStatementReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementReservationViews([item, item]).count == 2)
    }
}
