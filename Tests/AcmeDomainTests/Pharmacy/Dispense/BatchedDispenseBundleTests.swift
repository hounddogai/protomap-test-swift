@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseBundleTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newBatchedDispenseBundle("code-133", label: "label-786")
        #expect(item.status == Pharmacy.BatchedDispenseBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newBatchedDispenseBundle("code-133", label: "label-786")
        try item.moveTo(Pharmacy.BatchedDispenseBundleStatus.running)
        #expect(item.status == Pharmacy.BatchedDispenseBundleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newBatchedDispenseBundle("code-133", label: "label-786")
        item.status = Pharmacy.BatchedDispenseBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedDispenseBundleStatus.new) }
    }
}
