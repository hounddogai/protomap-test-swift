@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementThresholdTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newLegacyStatementThreshold("code-256", label: "label-846")
        #expect(item.status == RevenueCycle.LegacyStatementThresholdStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newLegacyStatementThreshold("code-256", label: "label-846")
        try item.moveTo(RevenueCycle.LegacyStatementThresholdStatus.published)
        #expect(item.status == RevenueCycle.LegacyStatementThresholdStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newLegacyStatementThreshold("code-256", label: "label-846")
        item.status = RevenueCycle.LegacyStatementThresholdStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyStatementThresholdStatus.created) }
    }
}
