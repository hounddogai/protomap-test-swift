@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedResultRequestTests {
    @Test func startsInProposed() throws {
        let item = Labs.newWeightedResultRequest("code-480", label: "label-545")
        #expect(item.status == Labs.WeightedResultRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newWeightedResultRequest("code-480", label: "label-545")
        try item.moveTo(Labs.WeightedResultRequestStatus.rejected)
        #expect(item.status == Labs.WeightedResultRequestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newWeightedResultRequest("code-480", label: "label-545")
        item.status = Labs.WeightedResultRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedResultRequestStatus.proposed) }
    }
}
