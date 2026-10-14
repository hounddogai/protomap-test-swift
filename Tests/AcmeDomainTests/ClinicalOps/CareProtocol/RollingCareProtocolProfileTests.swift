@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingCareProtocolProfileTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRollingCareProtocolProfile("code-782", title: "title-989")
        #expect(item.status == ClinicalOps.RollingCareProtocolProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newRollingCareProtocolProfile("code-782", title: "title-989")
        try item.moveTo(ClinicalOps.RollingCareProtocolProfileStatus.granted)
        #expect(item.status == ClinicalOps.RollingCareProtocolProfileStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRollingCareProtocolProfile("code-782", title: "title-989")
        item.status = ClinicalOps.RollingCareProtocolProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingCareProtocolProfileStatus.requested) }
    }
}
