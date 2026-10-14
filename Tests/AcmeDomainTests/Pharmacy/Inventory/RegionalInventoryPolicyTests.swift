@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInventoryPolicyTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newRegionalInventoryPolicy("code-732", title: "title-976")
        #expect(item.status == Pharmacy.RegionalInventoryPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newRegionalInventoryPolicy("code-732", title: "title-976")
        try item.moveTo(Pharmacy.RegionalInventoryPolicyStatus.ready)
        #expect(item.status == Pharmacy.RegionalInventoryPolicyStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newRegionalInventoryPolicy("code-732", title: "title-976")
        item.status = Pharmacy.RegionalInventoryPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalInventoryPolicyStatus.idle) }
    }
}
