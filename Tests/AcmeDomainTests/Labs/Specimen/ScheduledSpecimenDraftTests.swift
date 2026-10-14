@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenDraftTests {
    @Test func startsInCreated() throws {
        let item = Labs.newScheduledSpecimenDraft("code-908", title: "title-2")
        #expect(item.status == Labs.ScheduledSpecimenDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newScheduledSpecimenDraft("code-908", title: "title-2")
        try item.moveTo(Labs.ScheduledSpecimenDraftStatus.validated)
        #expect(item.status == Labs.ScheduledSpecimenDraftStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newScheduledSpecimenDraft("code-908", title: "title-2")
        item.status = Labs.ScheduledSpecimenDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledSpecimenDraftStatus.created) }
    }
}
