@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetProfileTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetProfile("code-594", name: "name-151")
        #expect(item.status == ClinicalOps.OrderSetProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newOrderSetProfile("code-594", name: "name-151")
        try item.moveTo(ClinicalOps.OrderSetProfileStatus.active)
        #expect(item.status == ClinicalOps.OrderSetProfileStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetProfile("code-594", name: "name-151")
        item.status = ClinicalOps.OrderSetProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetProfileStatus.draft) }
    }
}
