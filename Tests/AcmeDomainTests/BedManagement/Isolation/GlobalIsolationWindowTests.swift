@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalIsolationWindowTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newGlobalIsolationWindow("code-868", label: "label-458")
        #expect(item.status == BedManagement.GlobalIsolationWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newGlobalIsolationWindow("code-868", label: "label-458")
        try item.moveTo(BedManagement.GlobalIsolationWindowStatus.validated)
        #expect(item.status == BedManagement.GlobalIsolationWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newGlobalIsolationWindow("code-868", label: "label-458")
        item.status = BedManagement.GlobalIsolationWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalIsolationWindowStatus.created) }
    }
}
