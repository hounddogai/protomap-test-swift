@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceRecordTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newManualRemittanceRecord("code-985", name: "name-410")
        #expect(item.status == RevenueCycle.ManualRemittanceRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newManualRemittanceRecord("code-985", name: "name-410")
        try item.moveTo(RevenueCycle.ManualRemittanceRecordStatus.pending)
        #expect(item.status == RevenueCycle.ManualRemittanceRecordStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newManualRemittanceRecord("code-985", name: "name-410")
        item.status = RevenueCycle.ManualRemittanceRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualRemittanceRecordStatus.draft) }
    }
}
