@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachSegmentTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newOutreachSegment("code-622", title: "title-368")
        #expect(item.status == CareManagement.OutreachSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newOutreachSegment("code-622", title: "title-368")
        try item.moveTo(CareManagement.OutreachSegmentStatus.approved)
        #expect(item.status == CareManagement.OutreachSegmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newOutreachSegment("code-622", title: "title-368")
        item.status = CareManagement.OutreachSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachSegmentStatus.proposed) }
    }
}
