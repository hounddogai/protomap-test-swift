@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementRecordTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newLegacyStatementRecord("code-408", title: "title-37")
        #expect(item.status == RevenueCycle.LegacyStatementRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newLegacyStatementRecord("code-408", title: "title-37")
        try item.moveTo(RevenueCycle.LegacyStatementRecordStatus.stopped)
        #expect(item.status == RevenueCycle.LegacyStatementRecordStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newLegacyStatementRecord("code-408", title: "title-37")
        item.status = RevenueCycle.LegacyStatementRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyStatementRecordStatus.idle) }
    }
}
