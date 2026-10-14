@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenBatchTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newAdaptiveSpecimenBatch("code-776", name: "name-827")
        #expect(item.status == Labs.AdaptiveSpecimenBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newAdaptiveSpecimenBatch("code-776", name: "name-827")
        try item.moveTo(Labs.AdaptiveSpecimenBatchStatus.scheduled)
        #expect(item.status == Labs.AdaptiveSpecimenBatchStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newAdaptiveSpecimenBatch("code-776", name: "name-827")
        item.status = Labs.AdaptiveSpecimenBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveSpecimenBatchStatus.planned) }
    }
}
