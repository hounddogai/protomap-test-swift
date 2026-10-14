@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationBaselineTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newRegionalIsolationBaseline("code-425", name: "name-84")
        #expect(item.status == BedManagement.RegionalIsolationBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newRegionalIsolationBaseline("code-425", name: "name-84")
        try item.moveTo(BedManagement.RegionalIsolationBaselineStatus.approved)
        #expect(item.status == BedManagement.RegionalIsolationBaselineStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newRegionalIsolationBaseline("code-425", name: "name-84")
        item.status = BedManagement.RegionalIsolationBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalIsolationBaselineStatus.proposed) }
    }
}
