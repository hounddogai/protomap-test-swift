@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramDigestTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCappedProgramDigest("code-127", label: "label-881")
        #expect(item.status == CareManagement.CappedProgramDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newCappedProgramDigest("code-127", label: "label-881")
        try item.moveTo(CareManagement.CappedProgramDigestStatus.reopened)
        #expect(item.status == CareManagement.CappedProgramDigestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCappedProgramDigest("code-127", label: "label-881")
        item.status = CareManagement.CappedProgramDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedProgramDigestStatus.`open`) }
    }
}
