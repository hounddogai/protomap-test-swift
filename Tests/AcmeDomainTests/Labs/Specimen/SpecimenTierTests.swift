@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenTierTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newSpecimenTier("code-120", label: "label-501")
        #expect(item.status == Labs.SpecimenTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newSpecimenTier("code-120", label: "label-501")
        try item.moveTo(Labs.SpecimenTierStatus.scheduled)
        #expect(item.status == Labs.SpecimenTierStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newSpecimenTier("code-120", label: "label-501")
        item.status = Labs.SpecimenTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenTierStatus.planned) }
    }
}
