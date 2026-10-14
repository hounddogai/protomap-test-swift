@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedStatementReservation("code-733", label: "label-766")
        let view = RevenueCycle.toBatchedStatementReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedStatementReservationViews([item, item]).count == 2)
    }
}
