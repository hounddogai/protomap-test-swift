@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeClaimTests {
    @Test func startsInNew() throws {
        let item = Labs.newReferenceRangeClaim("code-456", label: "label-997")
        #expect(item.status == Labs.ReferenceRangeClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newReferenceRangeClaim("code-456", label: "label-997")
        try item.moveTo(Labs.ReferenceRangeClaimStatus.running)
        #expect(item.status == Labs.ReferenceRangeClaimStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newReferenceRangeClaim("code-456", label: "label-997")
        item.status = Labs.ReferenceRangeClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeClaimStatus.new) }
    }
}
