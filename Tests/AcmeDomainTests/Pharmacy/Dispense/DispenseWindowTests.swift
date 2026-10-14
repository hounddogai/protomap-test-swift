@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseWindowTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newDispenseWindow("code-116", name: "name-614")
        #expect(item.status == Pharmacy.DispenseWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newDispenseWindow("code-116", name: "name-614")
        try item.moveTo(Pharmacy.DispenseWindowStatus.active)
        #expect(item.status == Pharmacy.DispenseWindowStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newDispenseWindow("code-116", name: "name-614")
        item.status = Pharmacy.DispenseWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseWindowStatus.draft) }
    }
}
