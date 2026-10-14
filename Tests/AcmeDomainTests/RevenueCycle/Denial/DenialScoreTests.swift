@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialScoreTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newDenialScore("code-738", label: "label-943")
        #expect(item.status == RevenueCycle.DenialScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newDenialScore("code-738", label: "label-943")
        try item.moveTo(RevenueCycle.DenialScoreStatus.reopened)
        #expect(item.status == RevenueCycle.DenialScoreStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newDenialScore("code-738", label: "label-943")
        item.status = RevenueCycle.DenialScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialScoreStatus.`open`) }
    }
}
