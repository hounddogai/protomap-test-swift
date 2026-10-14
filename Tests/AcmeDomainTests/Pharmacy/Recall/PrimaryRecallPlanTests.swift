@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallPlanTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newPrimaryRecallPlan("code-599", label: "label-561")
        #expect(item.status == Pharmacy.PrimaryRecallPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Pharmacy.newPrimaryRecallPlan("code-599", label: "label-561")
        try item.moveTo(Pharmacy.PrimaryRecallPlanStatus.cancelled)
        #expect(item.status == Pharmacy.PrimaryRecallPlanStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newPrimaryRecallPlan("code-599", label: "label-561")
        item.status = Pharmacy.PrimaryRecallPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryRecallPlanStatus.planned) }
    }
}
