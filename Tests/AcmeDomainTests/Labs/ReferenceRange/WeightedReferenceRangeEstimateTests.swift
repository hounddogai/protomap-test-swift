@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedReferenceRangeEstimateTests {
    @Test func startsInProposed() throws {
        let item = Labs.newWeightedReferenceRangeEstimate("code-845", name: "name-27")
        #expect(item.status == Labs.WeightedReferenceRangeEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newWeightedReferenceRangeEstimate("code-845", name: "name-27")
        try item.moveTo(Labs.WeightedReferenceRangeEstimateStatus.rejected)
        #expect(item.status == Labs.WeightedReferenceRangeEstimateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newWeightedReferenceRangeEstimate("code-845", name: "name-27")
        item.status = Labs.WeightedReferenceRangeEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedReferenceRangeEstimateStatus.proposed) }
    }
}
