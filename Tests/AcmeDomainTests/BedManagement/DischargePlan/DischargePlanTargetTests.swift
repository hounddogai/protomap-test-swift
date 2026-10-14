@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanTargetTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newDischargePlanTarget("code-585", name: "name-894")
        #expect(item.status == BedManagement.DischargePlanTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newDischargePlanTarget("code-585", name: "name-894")
        try item.moveTo(BedManagement.DischargePlanTargetStatus.resolved)
        #expect(item.status == BedManagement.DischargePlanTargetStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newDischargePlanTarget("code-585", name: "name-894")
        item.status = BedManagement.DischargePlanTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanTargetStatus.`open`) }
    }
}
