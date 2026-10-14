@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationDigestTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newIsolationDigest("code-495", title: "title-515")
        #expect(item.status == BedManagement.IsolationDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newIsolationDigest("code-495", title: "title-515")
        try item.moveTo(BedManagement.IsolationDigestStatus.rejected)
        #expect(item.status == BedManagement.IsolationDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newIsolationDigest("code-495", title: "title-515")
        item.status = BedManagement.IsolationDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationDigestStatus.proposed) }
    }
}
