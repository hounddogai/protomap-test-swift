@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeVarianceTests {
    @Test func startsInNew() throws {
        let item = Labs.newFallbackReferenceRangeVariance("code-399", label: "label-960")
        #expect(item.status == Labs.FallbackReferenceRangeVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newFallbackReferenceRangeVariance("code-399", label: "label-960")
        try item.moveTo(Labs.FallbackReferenceRangeVarianceStatus.running)
        #expect(item.status == Labs.FallbackReferenceRangeVarianceStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newFallbackReferenceRangeVariance("code-399", label: "label-960")
        item.status = Labs.FallbackReferenceRangeVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackReferenceRangeVarianceStatus.new) }
    }
}
