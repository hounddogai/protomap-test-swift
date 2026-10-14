@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessScheduleTests {
    @Test func startsInNew() throws {
        let item = Consent.newWitnessSchedule("code-543", title: "title-193")
        #expect(item.status == Consent.WitnessScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newWitnessSchedule("code-543", title: "title-193")
        try item.moveTo(Consent.WitnessScheduleStatus.queued)
        #expect(item.status == Consent.WitnessScheduleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newWitnessSchedule("code-543", title: "title-193")
        item.status = Consent.WitnessScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessScheduleStatus.new) }
    }
}
