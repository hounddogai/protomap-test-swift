@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCleaningWindowTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newPendingCleaningWindow("code-292", label: "label-107")
        #expect(item.status == BedManagement.PendingCleaningWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newPendingCleaningWindow("code-292", label: "label-107")
        try item.moveTo(BedManagement.PendingCleaningWindowStatus.resolved)
        #expect(item.status == BedManagement.PendingCleaningWindowStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newPendingCleaningWindow("code-292", label: "label-107")
        item.status = BedManagement.PendingCleaningWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingCleaningWindowStatus.`open`) }
    }
}
