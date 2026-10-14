@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachSegmentTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newTieredOutreachSegment("code-928", label: "label-186")
        #expect(item.status == CareManagement.TieredOutreachSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newTieredOutreachSegment("code-928", label: "label-186")
        try item.moveTo(CareManagement.TieredOutreachSegmentStatus.validated)
        #expect(item.status == CareManagement.TieredOutreachSegmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newTieredOutreachSegment("code-928", label: "label-186")
        item.status = CareManagement.TieredOutreachSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredOutreachSegmentStatus.created) }
    }
}
