@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningEntryTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newFallbackCleaningEntry("code-730", name: "name-47")
        #expect(item.status == BedManagement.FallbackCleaningEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newFallbackCleaningEntry("code-730", name: "name-47")
        try item.moveTo(BedManagement.FallbackCleaningEntryStatus.resolved)
        #expect(item.status == BedManagement.FallbackCleaningEntryStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newFallbackCleaningEntry("code-730", name: "name-47")
        item.status = BedManagement.FallbackCleaningEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackCleaningEntryStatus.`open`) }
    }
}
