@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = Labs.newReferenceRangeAdjustment("code-525", label: "label-381")
        #expect(item.status == Labs.ReferenceRangeAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newReferenceRangeAdjustment("code-525", label: "label-381")
        try item.moveTo(Labs.ReferenceRangeAdjustmentStatus.validated)
        #expect(item.status == Labs.ReferenceRangeAdjustmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newReferenceRangeAdjustment("code-525", label: "label-381")
        item.status = Labs.ReferenceRangeAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeAdjustmentStatus.created) }
    }
}
