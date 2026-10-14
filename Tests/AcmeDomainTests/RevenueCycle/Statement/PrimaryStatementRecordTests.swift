@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryStatementRecordTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newPrimaryStatementRecord("code-440", name: "name-697")
        #expect(item.status == RevenueCycle.PrimaryStatementRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newPrimaryStatementRecord("code-440", name: "name-697")
        try item.moveTo(RevenueCycle.PrimaryStatementRecordStatus.active)
        #expect(item.status == RevenueCycle.PrimaryStatementRecordStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newPrimaryStatementRecord("code-440", name: "name-697")
        item.status = RevenueCycle.PrimaryStatementRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PrimaryStatementRecordStatus.draft) }
    }
}
