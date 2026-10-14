@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newFormularyMilestone("code-411", label: "label-662")
        #expect(item.status == Pharmacy.FormularyMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newFormularyMilestone("code-411", label: "label-662")
        try item.moveTo(Pharmacy.FormularyMilestoneStatus.revoked)
        #expect(item.status == Pharmacy.FormularyMilestoneStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newFormularyMilestone("code-411", label: "label-662")
        item.status = Pharmacy.FormularyMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyMilestoneStatus.requested) }
    }
}
