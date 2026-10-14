@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramCycleTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newCappedProgramCycle("code-910", label: "label-110")
        #expect(item.status == CareManagement.CappedProgramCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newCappedProgramCycle("code-910", label: "label-110")
        try item.moveTo(CareManagement.CappedProgramCycleStatus.expired)
        #expect(item.status == CareManagement.CappedProgramCycleStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newCappedProgramCycle("code-910", label: "label-110")
        item.status = CareManagement.CappedProgramCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedProgramCycleStatus.requested) }
    }
}
