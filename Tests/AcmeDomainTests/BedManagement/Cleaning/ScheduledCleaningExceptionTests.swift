@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningExceptionTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newScheduledCleaningException("code-35", name: "name-111")
        #expect(item.status == BedManagement.ScheduledCleaningExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newScheduledCleaningException("code-35", name: "name-111")
        try item.moveTo(BedManagement.ScheduledCleaningExceptionStatus.published)
        #expect(item.status == BedManagement.ScheduledCleaningExceptionStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newScheduledCleaningException("code-35", name: "name-111")
        item.status = BedManagement.ScheduledCleaningExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCleaningExceptionStatus.created) }
    }
}
