@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyRoundingMappingTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newLegacyRoundingMapping("code-242", title: "title-385")
        #expect(item.status == ClinicalOps.LegacyRoundingMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newLegacyRoundingMapping("code-242", title: "title-385")
        try item.moveTo(ClinicalOps.LegacyRoundingMappingStatus.ready)
        #expect(item.status == ClinicalOps.LegacyRoundingMappingStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newLegacyRoundingMapping("code-242", title: "title-385")
        item.status = ClinicalOps.LegacyRoundingMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyRoundingMappingStatus.idle) }
    }
}
