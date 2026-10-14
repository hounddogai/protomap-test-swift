@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolDigestTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newCareProtocolDigest("code-139", name: "name-733")
        #expect(item.status == ClinicalOps.CareProtocolDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newCareProtocolDigest("code-139", name: "name-733")
        try item.moveTo(ClinicalOps.CareProtocolDigestStatus.completed)
        #expect(item.status == ClinicalOps.CareProtocolDigestStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newCareProtocolDigest("code-139", name: "name-733")
        item.status = ClinicalOps.CareProtocolDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolDigestStatus.planned) }
    }
}
