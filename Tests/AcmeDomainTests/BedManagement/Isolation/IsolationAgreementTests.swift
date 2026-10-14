@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationAgreementTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newIsolationAgreement("code-57", name: "name-289")
        #expect(item.status == BedManagement.IsolationAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newIsolationAgreement("code-57", name: "name-289")
        try item.moveTo(BedManagement.IsolationAgreementStatus.warming)
        #expect(item.status == BedManagement.IsolationAgreementStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newIsolationAgreement("code-57", name: "name-289")
        item.status = BedManagement.IsolationAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationAgreementStatus.idle) }
    }
}
