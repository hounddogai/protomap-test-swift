@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallPlanTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRollingRecallPlan("code-718", name: "name-65")
        #expect(item.status == Pharmacy.RollingRecallPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newRollingRecallPlan("code-718", name: "name-65")
        try item.moveTo(Pharmacy.RollingRecallPlanStatus.scheduled)
        #expect(item.status == Pharmacy.RollingRecallPlanStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRollingRecallPlan("code-718", name: "name-65")
        item.status = Pharmacy.RollingRecallPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingRecallPlanStatus.planned) }
    }
}
