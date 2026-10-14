@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenQuotaTests {
    @Test func startsInOpen() throws {
        let item = Labs.newCappedSpecimenQuota("code-310", label: "label-298")
        #expect(item.status == Labs.CappedSpecimenQuotaStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newCappedSpecimenQuota("code-310", label: "label-298")
        try item.moveTo(Labs.CappedSpecimenQuotaStatus.reopened)
        #expect(item.status == Labs.CappedSpecimenQuotaStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newCappedSpecimenQuota("code-310", label: "label-298")
        item.status = Labs.CappedSpecimenQuotaStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedSpecimenQuotaStatus.`open`) }
    }
}
