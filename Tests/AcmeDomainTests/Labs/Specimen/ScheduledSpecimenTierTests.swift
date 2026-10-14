@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenTierTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newScheduledSpecimenTier("code-958", title: "title-534")
        #expect(item.status == Labs.ScheduledSpecimenTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newScheduledSpecimenTier("code-958", title: "title-534")
        try item.moveTo(Labs.ScheduledSpecimenTierStatus.inProgress)
        #expect(item.status == Labs.ScheduledSpecimenTierStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newScheduledSpecimenTier("code-958", title: "title-534")
        item.status = Labs.ScheduledSpecimenTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledSpecimenTierStatus.planned) }
    }
}
