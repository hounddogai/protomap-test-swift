@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualSubstitutionScoreTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newManualSubstitutionScore("code-14", title: "title-608")
        #expect(item.status == Pharmacy.ManualSubstitutionScoreStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newManualSubstitutionScore("code-14", title: "title-608")
        try item.moveTo(Pharmacy.ManualSubstitutionScoreStatus.warming)
        #expect(item.status == Pharmacy.ManualSubstitutionScoreStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newManualSubstitutionScore("code-14", title: "title-608")
        item.status = Pharmacy.ManualSubstitutionScoreStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualSubstitutionScoreStatus.idle) }
    }
}
