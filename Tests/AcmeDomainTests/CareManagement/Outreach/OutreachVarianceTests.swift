@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachVarianceTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newOutreachVariance("code-426", name: "name-779")
        #expect(item.status == CareManagement.OutreachVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newOutreachVariance("code-426", name: "name-779")
        try item.moveTo(CareManagement.OutreachVarianceStatus.rejected)
        #expect(item.status == CareManagement.OutreachVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newOutreachVariance("code-426", name: "name-779")
        item.status = CareManagement.OutreachVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachVarianceStatus.proposed) }
    }
}
