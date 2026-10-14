@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallEntryTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDefaultRecallEntry("code-585", name: "name-93")
        #expect(item.status == Pharmacy.DefaultRecallEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newDefaultRecallEntry("code-585", name: "name-93")
        try item.moveTo(Pharmacy.DefaultRecallEntryStatus.warming)
        #expect(item.status == Pharmacy.DefaultRecallEntryStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDefaultRecallEntry("code-585", name: "name-93")
        item.status = Pharmacy.DefaultRecallEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultRecallEntryStatus.idle) }
    }
}
