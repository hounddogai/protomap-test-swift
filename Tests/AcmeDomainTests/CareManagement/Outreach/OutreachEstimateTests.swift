@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachEstimateTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newOutreachEstimate("code-490", name: "name-771")
        #expect(item.status == CareManagement.OutreachEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newOutreachEstimate("code-490", name: "name-771")
        try item.moveTo(CareManagement.OutreachEstimateStatus.revoked)
        #expect(item.status == CareManagement.OutreachEstimateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newOutreachEstimate("code-490", name: "name-771")
        item.status = CareManagement.OutreachEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachEstimateStatus.requested) }
    }
}
