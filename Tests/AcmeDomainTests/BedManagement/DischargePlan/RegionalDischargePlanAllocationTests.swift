@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalDischargePlanAllocationTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newRegionalDischargePlanAllocation("code-533", label: "label-79")
        #expect(item.status == BedManagement.RegionalDischargePlanAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newRegionalDischargePlanAllocation("code-533", label: "label-79")
        try item.moveTo(BedManagement.RegionalDischargePlanAllocationStatus.resolved)
        #expect(item.status == BedManagement.RegionalDischargePlanAllocationStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newRegionalDischargePlanAllocation("code-533", label: "label-79")
        item.status = BedManagement.RegionalDischargePlanAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalDischargePlanAllocationStatus.`open`) }
    }
}
