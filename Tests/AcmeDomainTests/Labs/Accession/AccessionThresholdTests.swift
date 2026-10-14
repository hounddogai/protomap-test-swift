@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionThresholdTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAccessionThreshold("code-355", label: "label-855")
        #expect(item.status == Labs.AccessionThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newAccessionThreshold("code-355", label: "label-855")
        try item.moveTo(Labs.AccessionThresholdStatus.approved)
        #expect(item.status == Labs.AccessionThresholdStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAccessionThreshold("code-355", label: "label-855")
        item.status = Labs.AccessionThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionThresholdStatus.proposed) }
    }
}
