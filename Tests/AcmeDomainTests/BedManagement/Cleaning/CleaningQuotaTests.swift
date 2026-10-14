@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningQuotaTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newCleaningQuota("code-438", label: "label-933")
        #expect(item.status == BedManagement.CleaningQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newCleaningQuota("code-438", label: "label-933")
        try item.moveTo(BedManagement.CleaningQuotaStatus.validated)
        #expect(item.status == BedManagement.CleaningQuotaStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newCleaningQuota("code-438", label: "label-933")
        item.status = BedManagement.CleaningQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningQuotaStatus.created) }
    }
}
