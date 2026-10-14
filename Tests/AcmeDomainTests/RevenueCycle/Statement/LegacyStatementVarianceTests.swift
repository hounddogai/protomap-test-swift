@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementVarianceTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newLegacyStatementVariance("code-873", label: "label-335")
        #expect(item.status == RevenueCycle.LegacyStatementVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newLegacyStatementVariance("code-873", label: "label-335")
        try item.moveTo(RevenueCycle.LegacyStatementVarianceStatus.retired)
        #expect(item.status == RevenueCycle.LegacyStatementVarianceStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newLegacyStatementVariance("code-873", label: "label-335")
        item.status = RevenueCycle.LegacyStatementVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyStatementVarianceStatus.created) }
    }
}
