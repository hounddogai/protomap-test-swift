@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanMappingTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newAcuityPlanMapping("code-378", title: "title-385")
        #expect(item.status == Staffing.AcuityPlanMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newAcuityPlanMapping("code-378", title: "title-385")
        try item.moveTo(Staffing.AcuityPlanMappingStatus.inReview)
        #expect(item.status == Staffing.AcuityPlanMappingStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newAcuityPlanMapping("code-378", title: "title-385")
        item.status = Staffing.AcuityPlanMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanMappingStatus.`open`) }
    }
}
