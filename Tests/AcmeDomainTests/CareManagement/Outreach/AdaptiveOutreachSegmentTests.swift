@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachSegmentTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newAdaptiveOutreachSegment("code-628", name: "name-684")
        #expect(item.status == CareManagement.AdaptiveOutreachSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = CareManagement.newAdaptiveOutreachSegment("code-628", name: "name-684")
        try item.moveTo(CareManagement.AdaptiveOutreachSegmentStatus.withdrawn)
        #expect(item.status == CareManagement.AdaptiveOutreachSegmentStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newAdaptiveOutreachSegment("code-628", name: "name-684")
        item.status = CareManagement.AdaptiveOutreachSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveOutreachSegmentStatus.proposed) }
    }
}
