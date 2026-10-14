@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyScheduleTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFormularySchedule("code-880", name: "name-493")
        #expect(item.status == Pharmacy.FormularyScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newFormularySchedule("code-880", name: "name-493")
        try item.moveTo(Pharmacy.FormularyScheduleStatus.approved)
        #expect(item.status == Pharmacy.FormularyScheduleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFormularySchedule("code-880", name: "name-493")
        item.status = Pharmacy.FormularyScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyScheduleStatus.proposed) }
    }
}
