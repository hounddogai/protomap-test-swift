@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskEntryTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newFallbackTaskEntry("code-555", title: "title-484")
        #expect(item.status == ClinicalOps.FallbackTaskEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = ClinicalOps.newFallbackTaskEntry("code-555", title: "title-484")
        try item.moveTo(ClinicalOps.FallbackTaskEntryStatus.stopped)
        #expect(item.status == ClinicalOps.FallbackTaskEntryStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newFallbackTaskEntry("code-555", title: "title-484")
        item.status = ClinicalOps.FallbackTaskEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackTaskEntryStatus.idle) }
    }
}
