@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyChargeScoreTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newLegacyChargeScore("code-93", name: "name-489")
        #expect(item.status == RevenueCycle.LegacyChargeScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newLegacyChargeScore("code-93", name: "name-489")
        try item.moveTo(RevenueCycle.LegacyChargeScoreStatus.resolved)
        #expect(item.status == RevenueCycle.LegacyChargeScoreStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newLegacyChargeScore("code-93", name: "name-489")
        item.status = RevenueCycle.LegacyChargeScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyChargeScoreStatus.`open`) }
    }
}
