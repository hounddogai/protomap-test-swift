@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseProfileTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newDispenseProfile("code-704", name: "name-561")
        #expect(item.status == Pharmacy.DispenseProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newDispenseProfile("code-704", name: "name-561")
        try item.moveTo(Pharmacy.DispenseProfileStatus.completed)
        #expect(item.status == Pharmacy.DispenseProfileStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newDispenseProfile("code-704", name: "name-561")
        item.status = Pharmacy.DispenseProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseProfileStatus.planned) }
    }
}
