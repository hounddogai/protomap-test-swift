@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallBundleTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newWeightedRecallBundle("code-319", title: "title-961")
        #expect(item.status == Pharmacy.WeightedRecallBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newWeightedRecallBundle("code-319", title: "title-961")
        try item.moveTo(Pharmacy.WeightedRecallBundleStatus.ready)
        #expect(item.status == Pharmacy.WeightedRecallBundleStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newWeightedRecallBundle("code-319", title: "title-961")
        item.status = Pharmacy.WeightedRecallBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedRecallBundleStatus.idle) }
    }
}
