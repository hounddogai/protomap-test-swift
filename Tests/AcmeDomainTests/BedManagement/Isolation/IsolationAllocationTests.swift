@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationAllocationTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newIsolationAllocation("code-1", title: "title-918")
        #expect(item.status == BedManagement.IsolationAllocationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newIsolationAllocation("code-1", title: "title-918")
        try item.moveTo(BedManagement.IsolationAllocationStatus.validated)
        #expect(item.status == BedManagement.IsolationAllocationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newIsolationAllocation("code-1", title: "title-918")
        item.status = BedManagement.IsolationAllocationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationAllocationStatus.created) }
    }
}
