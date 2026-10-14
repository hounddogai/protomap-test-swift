@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTierTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newOutreachTier("code-371", title: "title-271")
        #expect(item.status == CareManagement.OutreachTierStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newOutreachTier("code-371", title: "title-271")
        try item.moveTo(CareManagement.OutreachTierStatus.rejected)
        #expect(item.status == CareManagement.OutreachTierStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newOutreachTier("code-371", title: "title-271")
        item.status = CareManagement.OutreachTierStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachTierStatus.proposed) }
    }
}
