@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBundleTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newDispenseBundle("code-808", title: "title-750")
        #expect(item.status == Pharmacy.DispenseBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newDispenseBundle("code-808", title: "title-750")
        try item.moveTo(Pharmacy.DispenseBundleStatus.revoked)
        #expect(item.status == Pharmacy.DispenseBundleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newDispenseBundle("code-808", title: "title-750")
        item.status = Pharmacy.DispenseBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseBundleStatus.requested) }
    }
}
