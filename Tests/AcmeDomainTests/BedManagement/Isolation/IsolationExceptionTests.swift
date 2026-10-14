@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationExceptionTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newIsolationException("code-230", title: "title-489")
        #expect(item.status == BedManagement.IsolationExceptionStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newIsolationException("code-230", title: "title-489")
        try item.moveTo(BedManagement.IsolationExceptionStatus.revoked)
        #expect(item.status == BedManagement.IsolationExceptionStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newIsolationException("code-230", title: "title-489")
        item.status = BedManagement.IsolationExceptionStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationExceptionStatus.requested) }
    }
}
