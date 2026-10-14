@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolRollupTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newCareProtocolRollup("code-289", name: "name-455")
        #expect(item.status == ClinicalOps.CareProtocolRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newCareProtocolRollup("code-289", name: "name-455")
        try item.moveTo(ClinicalOps.CareProtocolRollupStatus.granted)
        #expect(item.status == ClinicalOps.CareProtocolRollupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newCareProtocolRollup("code-289", name: "name-455")
        item.status = ClinicalOps.CareProtocolRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolRollupStatus.requested) }
    }
}
