@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationDigestTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newStrictIsolationDigest("code-570", title: "title-168")
        #expect(item.status == BedManagement.StrictIsolationDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newStrictIsolationDigest("code-570", title: "title-168")
        try item.moveTo(BedManagement.StrictIsolationDigestStatus.revoked)
        #expect(item.status == BedManagement.StrictIsolationDigestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newStrictIsolationDigest("code-570", title: "title-168")
        item.status = BedManagement.StrictIsolationDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictIsolationDigestStatus.requested) }
    }
}
