@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapCycleTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newCareGapCycle("code-302", title: "title-444")
        #expect(item.status == CareManagement.CareGapCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newCareGapCycle("code-302", title: "title-444")
        try item.moveTo(CareManagement.CareGapCycleStatus.draining)
        #expect(item.status == CareManagement.CareGapCycleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newCareGapCycle("code-302", title: "title-444")
        item.status = CareManagement.CareGapCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapCycleStatus.idle) }
    }
}
