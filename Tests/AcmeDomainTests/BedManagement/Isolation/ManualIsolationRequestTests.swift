@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualIsolationRequestTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newManualIsolationRequest("code-452", name: "name-531")
        #expect(item.status == BedManagement.ManualIsolationRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newManualIsolationRequest("code-452", name: "name-531")
        try item.moveTo(BedManagement.ManualIsolationRequestStatus.validated)
        #expect(item.status == BedManagement.ManualIsolationRequestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newManualIsolationRequest("code-452", name: "name-531")
        item.status = BedManagement.ManualIsolationRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualIsolationRequestStatus.created) }
    }
}
