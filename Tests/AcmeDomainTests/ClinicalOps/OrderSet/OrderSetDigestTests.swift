@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetDigestTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newOrderSetDigest("code-685", title: "title-455")
        #expect(item.status == ClinicalOps.OrderSetDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newOrderSetDigest("code-685", title: "title-455")
        try item.moveTo(ClinicalOps.OrderSetDigestStatus.scheduled)
        #expect(item.status == ClinicalOps.OrderSetDigestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newOrderSetDigest("code-685", title: "title-455")
        item.status = ClinicalOps.OrderSetDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetDigestStatus.planned) }
    }
}
