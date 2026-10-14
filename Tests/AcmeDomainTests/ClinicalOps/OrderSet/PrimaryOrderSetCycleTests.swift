@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetCycleTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newPrimaryOrderSetCycle("code-305", label: "label-356")
        #expect(item.status == ClinicalOps.PrimaryOrderSetCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newPrimaryOrderSetCycle("code-305", label: "label-356")
        try item.moveTo(ClinicalOps.PrimaryOrderSetCycleStatus.revoked)
        #expect(item.status == ClinicalOps.PrimaryOrderSetCycleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newPrimaryOrderSetCycle("code-305", label: "label-356")
        item.status = ClinicalOps.PrimaryOrderSetCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryOrderSetCycleStatus.requested) }
    }
}
