@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newOrderSetPreference("code-16", label: "label-203")
        #expect(item.status == ClinicalOps.OrderSetPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newOrderSetPreference("code-16", label: "label-203")
        try item.moveTo(ClinicalOps.OrderSetPreferenceStatus.scheduled)
        #expect(item.status == ClinicalOps.OrderSetPreferenceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newOrderSetPreference("code-16", label: "label-203")
        item.status = ClinicalOps.OrderSetPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetPreferenceStatus.planned) }
    }
}
