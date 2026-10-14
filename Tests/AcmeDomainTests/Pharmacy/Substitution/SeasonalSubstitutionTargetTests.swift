@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalSubstitutionTargetTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newSeasonalSubstitutionTarget("code-153", label: "label-256")
        #expect(item.status == Pharmacy.SeasonalSubstitutionTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newSeasonalSubstitutionTarget("code-153", label: "label-256")
        try item.moveTo(Pharmacy.SeasonalSubstitutionTargetStatus.running)
        #expect(item.status == Pharmacy.SeasonalSubstitutionTargetStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newSeasonalSubstitutionTarget("code-153", label: "label-256")
        item.status = Pharmacy.SeasonalSubstitutionTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalSubstitutionTargetStatus.new) }
    }
}
