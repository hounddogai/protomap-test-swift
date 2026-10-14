@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolEntryTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newCareProtocolEntry("code-540", label: "label-807")
        #expect(item.status == ClinicalOps.CareProtocolEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newCareProtocolEntry("code-540", label: "label-807")
        try item.moveTo(ClinicalOps.CareProtocolEntryStatus.rejected)
        #expect(item.status == ClinicalOps.CareProtocolEntryStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newCareProtocolEntry("code-540", label: "label-807")
        item.status = ClinicalOps.CareProtocolEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolEntryStatus.proposed) }
    }
}
