@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationRequestTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newIsolationRequest("code-820", label: "label-242")
        #expect(item.status == BedManagement.IsolationRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newIsolationRequest("code-820", label: "label-242")
        try item.moveTo(BedManagement.IsolationRequestStatus.warming)
        #expect(item.status == BedManagement.IsolationRequestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newIsolationRequest("code-820", label: "label-242")
        item.status = BedManagement.IsolationRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationRequestStatus.idle) }
    }
}
