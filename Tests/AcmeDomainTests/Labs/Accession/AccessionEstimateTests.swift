@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionEstimateTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAccessionEstimate("code-150", label: "label-847")
        #expect(item.status == Labs.AccessionEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newAccessionEstimate("code-150", label: "label-847")
        try item.moveTo(Labs.AccessionEstimateStatus.rejected)
        #expect(item.status == Labs.AccessionEstimateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAccessionEstimate("code-150", label: "label-847")
        item.status = Labs.AccessionEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionEstimateStatus.proposed) }
    }
}
