@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetTargetTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newOrderSetTarget("code-330", name: "name-993")
        #expect(item.status == ClinicalOps.OrderSetTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newOrderSetTarget("code-330", name: "name-993")
        try item.moveTo(ClinicalOps.OrderSetTargetStatus.validated)
        #expect(item.status == ClinicalOps.OrderSetTargetStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newOrderSetTarget("code-330", name: "name-993")
        item.status = ClinicalOps.OrderSetTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetTargetStatus.created) }
    }
}
