@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapDigestTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapDigest("code-869", name: "name-848")
        #expect(item.status == CareManagement.CareGapDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newCareGapDigest("code-869", name: "name-848")
        try item.moveTo(CareManagement.CareGapDigestStatus.resolved)
        #expect(item.status == CareManagement.CareGapDigestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapDigest("code-869", name: "name-848")
        item.status = CareManagement.CareGapDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapDigestStatus.`open`) }
    }
}
