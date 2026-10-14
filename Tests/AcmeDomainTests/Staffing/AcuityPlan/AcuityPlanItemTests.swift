@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanItemTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAcuityPlanItem("code-989", title: "title-872")
        #expect(item.status == Staffing.AcuityPlanItemStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newAcuityPlanItem("code-989", title: "title-872")
        try item.moveTo(Staffing.AcuityPlanItemStatus.approved)
        #expect(item.status == Staffing.AcuityPlanItemStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAcuityPlanItem("code-989", title: "title-872")
        item.status = Staffing.AcuityPlanItemStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanItemStatus.proposed) }
    }
}
