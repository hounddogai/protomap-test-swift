@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryTransferAssignmentTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newPrimaryTransferAssignment("code-153", name: "name-45")
        #expect(item.status == BedManagement.PrimaryTransferAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newPrimaryTransferAssignment("code-153", name: "name-45")
        try item.moveTo(BedManagement.PrimaryTransferAssignmentStatus.resolved)
        #expect(item.status == BedManagement.PrimaryTransferAssignmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newPrimaryTransferAssignment("code-153", name: "name-45")
        item.status = BedManagement.PrimaryTransferAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryTransferAssignmentStatus.`open`) }
    }
}
