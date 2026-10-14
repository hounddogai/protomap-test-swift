@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Consent.newScheduledWitnessMilestone("code-874", title: "title-355")
        #expect(item.status == Consent.ScheduledWitnessMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newScheduledWitnessMilestone("code-874", title: "title-355")
        try item.moveTo(Consent.ScheduledWitnessMilestoneStatus.granted)
        #expect(item.status == Consent.ScheduledWitnessMilestoneStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newScheduledWitnessMilestone("code-874", title: "title-355")
        item.status = Consent.ScheduledWitnessMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledWitnessMilestoneStatus.requested) }
    }
}
