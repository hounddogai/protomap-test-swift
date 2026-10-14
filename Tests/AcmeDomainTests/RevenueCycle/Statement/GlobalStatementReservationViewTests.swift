@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalStatementReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newGlobalStatementReservation("code-967", label: "label-602")
        let view = RevenueCycle.toGlobalStatementReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toGlobalStatementReservationViews([item, item]).count == 2)
    }
}
