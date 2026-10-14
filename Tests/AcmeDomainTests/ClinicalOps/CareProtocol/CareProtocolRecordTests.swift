@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolRecordTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newCareProtocolRecord("code-643", name: "name-100")
        #expect(item.status == ClinicalOps.CareProtocolRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newCareProtocolRecord("code-643", name: "name-100")
        try item.moveTo(ClinicalOps.CareProtocolRecordStatus.withdrawn)
        #expect(item.status == ClinicalOps.CareProtocolRecordStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newCareProtocolRecord("code-643", name: "name-100")
        item.status = ClinicalOps.CareProtocolRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolRecordStatus.proposed) }
    }
}
