@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultDraftTests {
    @Test func startsInCreated() throws {
        let item = Labs.newAdaptiveResultDraft("code-913", name: "name-856")
        #expect(item.status == Labs.AdaptiveResultDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newAdaptiveResultDraft("code-913", name: "name-856")
        try item.moveTo(Labs.AdaptiveResultDraftStatus.validated)
        #expect(item.status == Labs.AdaptiveResultDraftStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newAdaptiveResultDraft("code-913", name: "name-856")
        item.status = Labs.AdaptiveResultDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveResultDraftStatus.created) }
    }
}
