@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeReservationTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newChargeReservation("code-554", title: "title-803")
        #expect(item.status == RevenueCycle.ChargeReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newChargeReservation("code-554", title: "title-803")
        try item.moveTo(RevenueCycle.ChargeReservationStatus.reopened)
        #expect(item.status == RevenueCycle.ChargeReservationStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newChargeReservation("code-554", title: "title-803")
        item.status = RevenueCycle.ChargeReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeReservationStatus.`open`) }
    }
}
