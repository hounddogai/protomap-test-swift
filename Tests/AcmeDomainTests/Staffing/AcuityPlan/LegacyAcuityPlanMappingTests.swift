@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyAcuityPlanMappingTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newLegacyAcuityPlanMapping("code-927", name: "name-51")
        #expect(item.status == Staffing.LegacyAcuityPlanMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newLegacyAcuityPlanMapping("code-927", name: "name-51")
        try item.moveTo(Staffing.LegacyAcuityPlanMappingStatus.closed)
        #expect(item.status == Staffing.LegacyAcuityPlanMappingStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newLegacyAcuityPlanMapping("code-927", name: "name-51")
        item.status = Staffing.LegacyAcuityPlanMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyAcuityPlanMappingStatus.draft) }
    }
}
