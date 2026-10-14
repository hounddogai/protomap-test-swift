@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallEstimateTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRecallEstimate("code-176", title: "title-281")
        #expect(item.status == Pharmacy.RecallEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newRecallEstimate("code-176", title: "title-281")
        try item.moveTo(Pharmacy.RecallEstimateStatus.queued)
        #expect(item.status == Pharmacy.RecallEstimateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRecallEstimate("code-176", title: "title-281")
        item.status = Pharmacy.RecallEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallEstimateStatus.new) }
    }
}
