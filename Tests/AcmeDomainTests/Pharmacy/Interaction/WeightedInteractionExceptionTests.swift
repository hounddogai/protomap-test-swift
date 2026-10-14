@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInteractionExceptionTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newWeightedInteractionException("code-978", title: "title-994")
        #expect(item.status == Pharmacy.WeightedInteractionExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newWeightedInteractionException("code-978", title: "title-994")
        try item.moveTo(Pharmacy.WeightedInteractionExceptionStatus.validated)
        #expect(item.status == Pharmacy.WeightedInteractionExceptionStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newWeightedInteractionException("code-978", title: "title-994")
        item.status = Pharmacy.WeightedInteractionExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedInteractionExceptionStatus.created) }
    }
}
