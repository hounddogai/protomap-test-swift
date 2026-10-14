@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachTargetTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newLenientOutreachTarget("code-575", title: "title-12")
        #expect(item.status == CareManagement.LenientOutreachTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newLenientOutreachTarget("code-575", title: "title-12")
        try item.moveTo(CareManagement.LenientOutreachTargetStatus.approved)
        #expect(item.status == CareManagement.LenientOutreachTargetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newLenientOutreachTarget("code-575", title: "title-12")
        item.status = CareManagement.LenientOutreachTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientOutreachTargetStatus.proposed) }
    }
}
