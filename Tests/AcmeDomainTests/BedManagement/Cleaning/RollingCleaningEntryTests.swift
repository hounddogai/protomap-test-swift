@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningEntryTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newRollingCleaningEntry("code-748", label: "label-216")
        #expect(item.status == BedManagement.RollingCleaningEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newRollingCleaningEntry("code-748", label: "label-216")
        try item.moveTo(BedManagement.RollingCleaningEntryStatus.running)
        #expect(item.status == BedManagement.RollingCleaningEntryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newRollingCleaningEntry("code-748", label: "label-216")
        item.status = BedManagement.RollingCleaningEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingCleaningEntryStatus.new) }
    }
}
