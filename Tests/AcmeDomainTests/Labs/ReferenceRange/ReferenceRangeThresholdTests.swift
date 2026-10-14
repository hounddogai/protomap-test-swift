@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeThresholdTests {
    @Test func startsInProposed() throws {
        let item = Labs.newReferenceRangeThreshold("code-461", name: "name-678")
        #expect(item.status == Labs.ReferenceRangeThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newReferenceRangeThreshold("code-461", name: "name-678")
        try item.moveTo(Labs.ReferenceRangeThresholdStatus.rejected)
        #expect(item.status == Labs.ReferenceRangeThresholdStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newReferenceRangeThreshold("code-461", name: "name-678")
        item.status = Labs.ReferenceRangeThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeThresholdStatus.proposed) }
    }
}
