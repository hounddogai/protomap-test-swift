@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRecordTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDispenseRecord("code-8", name: "name-207")
        #expect(item.status == Pharmacy.DispenseRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newDispenseRecord("code-8", name: "name-207")
        try item.moveTo(Pharmacy.DispenseRecordStatus.warming)
        #expect(item.status == Pharmacy.DispenseRecordStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDispenseRecord("code-8", name: "name-207")
        item.status = Pharmacy.DispenseRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseRecordStatus.idle) }
    }
}
