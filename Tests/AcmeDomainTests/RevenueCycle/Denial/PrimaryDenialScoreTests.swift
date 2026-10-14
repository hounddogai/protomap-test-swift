@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryDenialScoreTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newPrimaryDenialScore("code-954", name: "name-800")
        #expect(item.status == RevenueCycle.PrimaryDenialScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newPrimaryDenialScore("code-954", name: "name-800")
        try item.moveTo(RevenueCycle.PrimaryDenialScoreStatus.scheduled)
        #expect(item.status == RevenueCycle.PrimaryDenialScoreStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newPrimaryDenialScore("code-954", name: "name-800")
        item.status = RevenueCycle.PrimaryDenialScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PrimaryDenialScoreStatus.planned) }
    }
}
