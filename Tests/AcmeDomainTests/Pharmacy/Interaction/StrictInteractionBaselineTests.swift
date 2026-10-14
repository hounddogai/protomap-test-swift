@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInteractionBaselineTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newStrictInteractionBaseline("code-389", label: "label-908")
        #expect(item.status == Pharmacy.StrictInteractionBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newStrictInteractionBaseline("code-389", label: "label-908")
        try item.moveTo(Pharmacy.StrictInteractionBaselineStatus.inProgress)
        #expect(item.status == Pharmacy.StrictInteractionBaselineStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newStrictInteractionBaseline("code-389", label: "label-908")
        item.status = Pharmacy.StrictInteractionBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictInteractionBaselineStatus.planned) }
    }
}
