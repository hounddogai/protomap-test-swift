@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramCycleTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newAdaptiveProgramCycle("code-926", name: "name-349")
        #expect(item.status == CareManagement.AdaptiveProgramCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newAdaptiveProgramCycle("code-926", name: "name-349")
        try item.moveTo(CareManagement.AdaptiveProgramCycleStatus.suspended)
        #expect(item.status == CareManagement.AdaptiveProgramCycleStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newAdaptiveProgramCycle("code-926", name: "name-349")
        item.status = CareManagement.AdaptiveProgramCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveProgramCycleStatus.draft) }
    }
}
