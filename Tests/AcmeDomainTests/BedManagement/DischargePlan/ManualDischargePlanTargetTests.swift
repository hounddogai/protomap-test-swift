@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanTargetTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newManualDischargePlanTarget("code-923", label: "label-265")
        #expect(item.status == BedManagement.ManualDischargePlanTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newManualDischargePlanTarget("code-923", label: "label-265")
        try item.moveTo(BedManagement.ManualDischargePlanTargetStatus.resolved)
        #expect(item.status == BedManagement.ManualDischargePlanTargetStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newManualDischargePlanTarget("code-923", label: "label-265")
        item.status = BedManagement.ManualDischargePlanTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualDischargePlanTargetStatus.`open`) }
    }
}
