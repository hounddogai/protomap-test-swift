@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallWindowTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRecallWindow("code-442", title: "title-750")
        #expect(item.status == Pharmacy.RecallWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newRecallWindow("code-442", title: "title-750")
        try item.moveTo(Pharmacy.RecallWindowStatus.done)
        #expect(item.status == Pharmacy.RecallWindowStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRecallWindow("code-442", title: "title-750")
        item.status = Pharmacy.RecallWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallWindowStatus.new) }
    }
}
