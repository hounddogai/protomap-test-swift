@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryTaskTierTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newPrimaryTaskTier("code-509", title: "title-869")
        #expect(item.status == ClinicalOps.PrimaryTaskTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newPrimaryTaskTier("code-509", title: "title-869")
        try item.moveTo(ClinicalOps.PrimaryTaskTierStatus.done)
        #expect(item.status == ClinicalOps.PrimaryTaskTierStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newPrimaryTaskTier("code-509", title: "title-869")
        item.status = ClinicalOps.PrimaryTaskTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryTaskTierStatus.new) }
    }
}
