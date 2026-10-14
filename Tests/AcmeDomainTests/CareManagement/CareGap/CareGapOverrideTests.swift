@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapOverrideTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newCareGapOverride("code-615", title: "title-991")
        #expect(item.status == CareManagement.CareGapOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newCareGapOverride("code-615", title: "title-991")
        try item.moveTo(CareManagement.CareGapOverrideStatus.approved)
        #expect(item.status == CareManagement.CareGapOverrideStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newCareGapOverride("code-615", title: "title-991")
        item.status = CareManagement.CareGapOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapOverrideStatus.proposed) }
    }
}
