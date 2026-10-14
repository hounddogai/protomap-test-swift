@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalSegmentTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newLegacyGoalSegment("code-389", label: "label-715")
        #expect(item.status == CareManagement.LegacyGoalSegmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newLegacyGoalSegment("code-389", label: "label-715")
        try item.moveTo(CareManagement.LegacyGoalSegmentStatus.failed)
        #expect(item.status == CareManagement.LegacyGoalSegmentStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newLegacyGoalSegment("code-389", label: "label-715")
        item.status = CareManagement.LegacyGoalSegmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyGoalSegmentStatus.new) }
    }
}
