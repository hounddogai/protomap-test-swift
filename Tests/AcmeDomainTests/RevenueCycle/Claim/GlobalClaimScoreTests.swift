@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalClaimScoreTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newGlobalClaimScore("code-512", name: "name-690")
        #expect(item.status == RevenueCycle.GlobalClaimScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newGlobalClaimScore("code-512", name: "name-690")
        try item.moveTo(RevenueCycle.GlobalClaimScoreStatus.resolved)
        #expect(item.status == RevenueCycle.GlobalClaimScoreStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newGlobalClaimScore("code-512", name: "name-690")
        item.status = RevenueCycle.GlobalClaimScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalClaimScoreStatus.`open`) }
    }
}
