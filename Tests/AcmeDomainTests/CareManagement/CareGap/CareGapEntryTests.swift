@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapEntryTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newCareGapEntry("code-453", name: "name-369")
        #expect(item.status == CareManagement.CareGapEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newCareGapEntry("code-453", name: "name-369")
        try item.moveTo(CareManagement.CareGapEntryStatus.approved)
        #expect(item.status == CareManagement.CareGapEntryStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newCareGapEntry("code-453", name: "name-369")
        item.status = CareManagement.CareGapEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapEntryStatus.proposed) }
    }
}
