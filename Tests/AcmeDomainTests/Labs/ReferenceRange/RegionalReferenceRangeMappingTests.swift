@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalReferenceRangeMappingTests {
    @Test func startsInProposed() throws {
        let item = Labs.newRegionalReferenceRangeMapping("code-563", name: "name-374")
        #expect(item.status == Labs.RegionalReferenceRangeMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newRegionalReferenceRangeMapping("code-563", name: "name-374")
        try item.moveTo(Labs.RegionalReferenceRangeMappingStatus.rejected)
        #expect(item.status == Labs.RegionalReferenceRangeMappingStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newRegionalReferenceRangeMapping("code-563", name: "name-374")
        item.status = Labs.RegionalReferenceRangeMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalReferenceRangeMappingStatus.proposed) }
    }
}
