@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolProfileTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolProfile("code-989", title: "title-515")
        #expect(item.status == ClinicalOps.AdaptiveCareProtocolProfileStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolProfile("code-989", title: "title-515")
        try item.moveTo(ClinicalOps.AdaptiveCareProtocolProfileStatus.rejected)
        #expect(item.status == ClinicalOps.AdaptiveCareProtocolProfileStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolProfile("code-989", title: "title-515")
        item.status = ClinicalOps.AdaptiveCareProtocolProfileStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveCareProtocolProfileStatus.proposed) }
    }
}
