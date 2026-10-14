@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentMappingTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRollingAssessmentMapping("code-126", name: "name-402")
        #expect(item.status == CareManagement.RollingAssessmentMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newRollingAssessmentMapping("code-126", name: "name-402")
        try item.moveTo(CareManagement.RollingAssessmentMappingStatus.queued)
        #expect(item.status == CareManagement.RollingAssessmentMappingStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRollingAssessmentMapping("code-126", name: "name-402")
        item.status = CareManagement.RollingAssessmentMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingAssessmentMappingStatus.new) }
    }
}
