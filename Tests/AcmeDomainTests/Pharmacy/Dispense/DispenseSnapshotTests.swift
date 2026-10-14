@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSnapshotTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newDispenseSnapshot("code-318", name: "name-817")
        #expect(item.status == Pharmacy.DispenseSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newDispenseSnapshot("code-318", name: "name-817")
        try item.moveTo(Pharmacy.DispenseSnapshotStatus.revoked)
        #expect(item.status == Pharmacy.DispenseSnapshotStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newDispenseSnapshot("code-318", name: "name-817")
        item.status = Pharmacy.DispenseSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseSnapshotStatus.requested) }
    }
}
