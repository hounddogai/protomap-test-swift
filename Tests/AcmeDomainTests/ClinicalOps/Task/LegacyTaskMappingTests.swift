@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskMappingTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newLegacyTaskMapping("code-528", title: "title-607")
        #expect(item.status == ClinicalOps.LegacyTaskMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newLegacyTaskMapping("code-528", title: "title-607")
        try item.moveTo(ClinicalOps.LegacyTaskMappingStatus.scheduled)
        #expect(item.status == ClinicalOps.LegacyTaskMappingStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newLegacyTaskMapping("code-528", title: "title-607")
        item.status = ClinicalOps.LegacyTaskMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyTaskMappingStatus.planned) }
    }
}
