@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseOverrideTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newCappedDispenseOverride("code-60", title: "title-277")
        #expect(item.status == Pharmacy.CappedDispenseOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newCappedDispenseOverride("code-60", title: "title-277")
        try item.moveTo(Pharmacy.CappedDispenseOverrideStatus.warming)
        #expect(item.status == Pharmacy.CappedDispenseOverrideStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newCappedDispenseOverride("code-60", title: "title-277")
        item.status = Pharmacy.CappedDispenseOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedDispenseOverrideStatus.idle) }
    }
}
