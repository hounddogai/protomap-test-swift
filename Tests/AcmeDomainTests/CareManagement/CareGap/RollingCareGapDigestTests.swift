@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapDigestTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newRollingCareGapDigest("code-438", title: "title-974")
        #expect(item.status == CareManagement.RollingCareGapDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = CareManagement.newRollingCareGapDigest("code-438", title: "title-974")
        try item.moveTo(CareManagement.RollingCareGapDigestStatus.withdrawn)
        #expect(item.status == CareManagement.RollingCareGapDigestStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newRollingCareGapDigest("code-438", title: "title-974")
        item.status = CareManagement.RollingCareGapDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingCareGapDigestStatus.proposed) }
    }
}
