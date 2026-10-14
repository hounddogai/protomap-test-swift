@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionRollupTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newLenientSubstitutionRollup("code-6", label: "label-469")
        #expect(item.status == Pharmacy.LenientSubstitutionRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newLenientSubstitutionRollup("code-6", label: "label-469")
        try item.moveTo(Pharmacy.LenientSubstitutionRollupStatus.queued)
        #expect(item.status == Pharmacy.LenientSubstitutionRollupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newLenientSubstitutionRollup("code-6", label: "label-469")
        item.status = Pharmacy.LenientSubstitutionRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientSubstitutionRollupStatus.new) }
    }
}
