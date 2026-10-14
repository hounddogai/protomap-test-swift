@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapScheduleTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newRollingCareGapSchedule("code-810", title: "title-634")
        #expect(item.status == CareManagement.RollingCareGapScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newRollingCareGapSchedule("code-810", title: "title-634")
        try item.moveTo(CareManagement.RollingCareGapScheduleStatus.validated)
        #expect(item.status == CareManagement.RollingCareGapScheduleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newRollingCareGapSchedule("code-810", title: "title-634")
        item.status = CareManagement.RollingCareGapScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingCareGapScheduleStatus.created) }
    }
}
