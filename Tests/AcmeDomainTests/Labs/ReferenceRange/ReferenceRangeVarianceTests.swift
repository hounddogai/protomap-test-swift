@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeVarianceTests {
    @Test func startsInNew() throws {
        let item = Labs.newReferenceRangeVariance("code-120", title: "title-36")
        #expect(item.status == Labs.ReferenceRangeVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newReferenceRangeVariance("code-120", title: "title-36")
        try item.moveTo(Labs.ReferenceRangeVarianceStatus.running)
        #expect(item.status == Labs.ReferenceRangeVarianceStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newReferenceRangeVariance("code-120", title: "title-36")
        item.status = Labs.ReferenceRangeVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeVarianceStatus.new) }
    }
}
