@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseEntryTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDefaultDispenseEntry("code-469", name: "name-796")
        #expect(item.status == Pharmacy.DefaultDispenseEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newDefaultDispenseEntry("code-469", name: "name-796")
        try item.moveTo(Pharmacy.DefaultDispenseEntryStatus.warming)
        #expect(item.status == Pharmacy.DefaultDispenseEntryStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDefaultDispenseEntry("code-469", name: "name-796")
        item.status = Pharmacy.DefaultDispenseEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultDispenseEntryStatus.idle) }
    }
}
