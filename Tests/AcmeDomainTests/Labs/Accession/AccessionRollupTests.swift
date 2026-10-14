@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionRollupTests {
    @Test func startsInCreated() throws {
        let item = Labs.newAccessionRollup("code-550", name: "name-838")
        #expect(item.status == Labs.AccessionRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newAccessionRollup("code-550", name: "name-838")
        try item.moveTo(Labs.AccessionRollupStatus.published)
        #expect(item.status == Labs.AccessionRollupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newAccessionRollup("code-550", name: "name-838")
        item.status = Labs.AccessionRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionRollupStatus.created) }
    }
}
