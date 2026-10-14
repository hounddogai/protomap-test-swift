@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultThresholdTests {
    @Test func startsInProposed() throws {
        let item = Labs.newResultThreshold("code-298", label: "label-969")
        #expect(item.status == Labs.ResultThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newResultThreshold("code-298", label: "label-969")
        try item.moveTo(Labs.ResultThresholdStatus.withdrawn)
        #expect(item.status == Labs.ResultThresholdStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newResultThreshold("code-298", label: "label-969")
        item.status = Labs.ResultThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultThresholdStatus.proposed) }
    }
}
