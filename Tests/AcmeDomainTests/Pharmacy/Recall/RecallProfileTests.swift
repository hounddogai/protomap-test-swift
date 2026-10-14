@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallProfileTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRecallProfile("code-636", name: "name-777")
        #expect(item.status == Pharmacy.RecallProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newRecallProfile("code-636", name: "name-777")
        try item.moveTo(Pharmacy.RecallProfileStatus.queued)
        #expect(item.status == Pharmacy.RecallProfileStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRecallProfile("code-636", name: "name-777")
        item.status = Pharmacy.RecallProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallProfileStatus.new) }
    }
}
