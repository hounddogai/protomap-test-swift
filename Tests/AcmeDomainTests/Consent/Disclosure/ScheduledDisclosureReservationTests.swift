@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledDisclosureReservationTests {
    @Test func startsInProposed() throws {
        let item = Consent.newScheduledDisclosureReservation("code-834", label: "label-760")
        #expect(item.status == Consent.ScheduledDisclosureReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newScheduledDisclosureReservation("code-834", label: "label-760")
        try item.moveTo(Consent.ScheduledDisclosureReservationStatus.approved)
        #expect(item.status == Consent.ScheduledDisclosureReservationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newScheduledDisclosureReservation("code-834", label: "label-760")
        item.status = Consent.ScheduledDisclosureReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledDisclosureReservationStatus.proposed) }
    }
}
