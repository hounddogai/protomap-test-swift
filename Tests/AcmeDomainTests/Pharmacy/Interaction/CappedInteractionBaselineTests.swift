@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInteractionBaselineTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newCappedInteractionBaseline("code-569", title: "title-444")
        #expect(item.status == Pharmacy.CappedInteractionBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newCappedInteractionBaseline("code-569", title: "title-444")
        try item.moveTo(Pharmacy.CappedInteractionBaselineStatus.queued)
        #expect(item.status == Pharmacy.CappedInteractionBaselineStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newCappedInteractionBaseline("code-569", title: "title-444")
        item.status = Pharmacy.CappedInteractionBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedInteractionBaselineStatus.new) }
    }
}
