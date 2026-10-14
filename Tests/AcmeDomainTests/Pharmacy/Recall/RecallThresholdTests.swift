@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallThresholdTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRecallThreshold("code-124", name: "name-154")
        #expect(item.status == Pharmacy.RecallThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newRecallThreshold("code-124", name: "name-154")
        try item.moveTo(Pharmacy.RecallThresholdStatus.rejected)
        #expect(item.status == Pharmacy.RecallThresholdStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRecallThreshold("code-124", name: "name-154")
        item.status = Pharmacy.RecallThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallThresholdStatus.proposed) }
    }
}
