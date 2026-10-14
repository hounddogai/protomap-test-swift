@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularyRecordTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newDefaultFormularyRecord("code-607", name: "name-826")
        #expect(item.status == Pharmacy.DefaultFormularyRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newDefaultFormularyRecord("code-607", name: "name-826")
        try item.moveTo(Pharmacy.DefaultFormularyRecordStatus.queued)
        #expect(item.status == Pharmacy.DefaultFormularyRecordStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newDefaultFormularyRecord("code-607", name: "name-826")
        item.status = Pharmacy.DefaultFormularyRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultFormularyRecordStatus.new) }
    }
}
