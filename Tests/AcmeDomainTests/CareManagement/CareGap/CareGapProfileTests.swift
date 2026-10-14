@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapProfileTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newCareGapProfile("code-690", name: "name-619")
        #expect(item.status == CareManagement.CareGapProfileStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newCareGapProfile("code-690", name: "name-619")
        try item.moveTo(CareManagement.CareGapProfileStatus.rejected)
        #expect(item.status == CareManagement.CareGapProfileStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newCareGapProfile("code-690", name: "name-619")
        item.status = CareManagement.CareGapProfileStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapProfileStatus.proposed) }
    }
}
