@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionQuotaTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newInteractionQuota("code-949", label: "label-881")
        #expect(item.status == Pharmacy.InteractionQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newInteractionQuota("code-949", label: "label-881")
        try item.moveTo(Pharmacy.InteractionQuotaStatus.expired)
        #expect(item.status == Pharmacy.InteractionQuotaStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newInteractionQuota("code-949", label: "label-881")
        item.status = Pharmacy.InteractionQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionQuotaStatus.requested) }
    }
}
