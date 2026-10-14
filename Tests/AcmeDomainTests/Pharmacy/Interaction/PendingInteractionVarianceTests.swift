@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInteractionVarianceTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newPendingInteractionVariance("code-422", label: "label-964")
        #expect(item.status == Pharmacy.PendingInteractionVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newPendingInteractionVariance("code-422", label: "label-964")
        try item.moveTo(Pharmacy.PendingInteractionVarianceStatus.completed)
        #expect(item.status == Pharmacy.PendingInteractionVarianceStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newPendingInteractionVariance("code-422", label: "label-964")
        item.status = Pharmacy.PendingInteractionVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingInteractionVarianceStatus.planned) }
    }
}
