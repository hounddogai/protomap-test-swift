@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultOverrideTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newCappedResultOverride("code-288", name: "name-799")
        #expect(item.status == Labs.CappedResultOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Labs.newCappedResultOverride("code-288", name: "name-799")
        try item.moveTo(Labs.CappedResultOverrideStatus.cancelled)
        #expect(item.status == Labs.CappedResultOverrideStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newCappedResultOverride("code-288", name: "name-799")
        item.status = Labs.CappedResultOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedResultOverrideStatus.planned) }
    }
}
