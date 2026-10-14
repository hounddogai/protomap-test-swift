@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementManifestTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newStatementManifest("code-801", label: "label-891")
        #expect(item.status == RevenueCycle.StatementManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newStatementManifest("code-801", label: "label-891")
        try item.moveTo(RevenueCycle.StatementManifestStatus.inReview)
        #expect(item.status == RevenueCycle.StatementManifestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newStatementManifest("code-801", label: "label-891")
        item.status = RevenueCycle.StatementManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementManifestStatus.`open`) }
    }
}
