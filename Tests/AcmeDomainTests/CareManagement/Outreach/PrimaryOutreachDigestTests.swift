@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachDigestTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newPrimaryOutreachDigest("code-967", title: "title-167")
        #expect(item.status == CareManagement.PrimaryOutreachDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newPrimaryOutreachDigest("code-967", title: "title-167")
        try item.moveTo(CareManagement.PrimaryOutreachDigestStatus.running)
        #expect(item.status == CareManagement.PrimaryOutreachDigestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newPrimaryOutreachDigest("code-967", title: "title-167")
        item.status = CareManagement.PrimaryOutreachDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryOutreachDigestStatus.new) }
    }
}
