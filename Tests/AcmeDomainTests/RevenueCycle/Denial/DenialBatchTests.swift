@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBatchTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newDenialBatch("code-830", label: "label-971")
        #expect(item.status == RevenueCycle.DenialBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newDenialBatch("code-830", label: "label-971")
        try item.moveTo(RevenueCycle.DenialBatchStatus.scheduled)
        #expect(item.status == RevenueCycle.DenialBatchStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newDenialBatch("code-830", label: "label-971")
        item.status = RevenueCycle.DenialBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialBatchStatus.planned) }
    }
}
