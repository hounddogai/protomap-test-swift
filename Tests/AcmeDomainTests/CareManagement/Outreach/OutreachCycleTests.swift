@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachCycleTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newOutreachCycle("code-330", name: "name-124")
        #expect(item.status == CareManagement.OutreachCycleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newOutreachCycle("code-330", name: "name-124")
        try item.moveTo(CareManagement.OutreachCycleStatus.approved)
        #expect(item.status == CareManagement.OutreachCycleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newOutreachCycle("code-330", name: "name-124")
        item.status = CareManagement.OutreachCycleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachCycleStatus.proposed) }
    }
}
