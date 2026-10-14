@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalAssessmentSnapshotTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newSeasonalAssessmentSnapshot("code-872", title: "title-979")
        #expect(item.status == CareManagement.SeasonalAssessmentSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newSeasonalAssessmentSnapshot("code-872", title: "title-979")
        try item.moveTo(CareManagement.SeasonalAssessmentSnapshotStatus.revoked)
        #expect(item.status == CareManagement.SeasonalAssessmentSnapshotStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newSeasonalAssessmentSnapshot("code-872", title: "title-979")
        item.status = CareManagement.SeasonalAssessmentSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalAssessmentSnapshotStatus.requested) }
    }
}
