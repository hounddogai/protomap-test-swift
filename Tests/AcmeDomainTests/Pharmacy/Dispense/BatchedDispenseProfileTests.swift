@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseProfileTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newBatchedDispenseProfile("code-294", name: "name-351")
        #expect(item.status == Pharmacy.BatchedDispenseProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newBatchedDispenseProfile("code-294", name: "name-351")
        try item.moveTo(Pharmacy.BatchedDispenseProfileStatus.revoked)
        #expect(item.status == Pharmacy.BatchedDispenseProfileStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newBatchedDispenseProfile("code-294", name: "name-351")
        item.status = Pharmacy.BatchedDispenseProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedDispenseProfileStatus.requested) }
    }
}
