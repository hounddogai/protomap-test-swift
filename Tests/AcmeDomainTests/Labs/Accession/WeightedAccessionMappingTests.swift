@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedAccessionMappingTests {
    @Test func startsInCreated() throws {
        let item = Labs.newWeightedAccessionMapping("code-835", title: "title-235")
        #expect(item.status == Labs.WeightedAccessionMappingStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Labs.newWeightedAccessionMapping("code-835", title: "title-235")
        try item.moveTo(Labs.WeightedAccessionMappingStatus.retired)
        #expect(item.status == Labs.WeightedAccessionMappingStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newWeightedAccessionMapping("code-835", title: "title-235")
        item.status = Labs.WeightedAccessionMappingStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedAccessionMappingStatus.created) }
    }
}
