@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceScoreTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRemittanceScore("code-492", name: "name-334")
        #expect(item.status == RevenueCycle.RemittanceScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newRemittanceScore("code-492", name: "name-334")
        try item.moveTo(RevenueCycle.RemittanceScoreStatus.validated)
        #expect(item.status == RevenueCycle.RemittanceScoreStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRemittanceScore("code-492", name: "name-334")
        item.status = RevenueCycle.RemittanceScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceScoreStatus.created) }
    }
}
