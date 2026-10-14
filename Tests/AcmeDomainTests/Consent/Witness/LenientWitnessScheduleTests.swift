@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientWitnessScheduleTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLenientWitnessSchedule("code-886", title: "title-107")
        #expect(item.status == Consent.LenientWitnessScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newLenientWitnessSchedule("code-886", title: "title-107")
        try item.moveTo(Consent.LenientWitnessScheduleStatus.approved)
        #expect(item.status == Consent.LenientWitnessScheduleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLenientWitnessSchedule("code-886", title: "title-107")
        item.status = Consent.LenientWitnessScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientWitnessScheduleStatus.proposed) }
    }
}
