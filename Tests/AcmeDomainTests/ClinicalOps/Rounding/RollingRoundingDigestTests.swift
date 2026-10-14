@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingDigestTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRollingRoundingDigest("code-718", name: "name-943")
        #expect(item.status == ClinicalOps.RollingRoundingDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newRollingRoundingDigest("code-718", name: "name-943")
        try item.moveTo(ClinicalOps.RollingRoundingDigestStatus.granted)
        #expect(item.status == ClinicalOps.RollingRoundingDigestStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRollingRoundingDigest("code-718", name: "name-943")
        item.status = ClinicalOps.RollingRoundingDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingRoundingDigestStatus.requested) }
    }
}
