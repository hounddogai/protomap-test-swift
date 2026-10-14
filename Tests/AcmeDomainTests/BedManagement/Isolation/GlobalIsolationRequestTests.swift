@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalIsolationRequestTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newGlobalIsolationRequest("code-914", title: "title-863")
        #expect(item.status == BedManagement.GlobalIsolationRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = BedManagement.newGlobalIsolationRequest("code-914", title: "title-863")
        try item.moveTo(BedManagement.GlobalIsolationRequestStatus.completed)
        #expect(item.status == BedManagement.GlobalIsolationRequestStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newGlobalIsolationRequest("code-914", title: "title-863")
        item.status = BedManagement.GlobalIsolationRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalIsolationRequestStatus.planned) }
    }
}
