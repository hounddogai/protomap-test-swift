@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalSubstitutionExceptionTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newSeasonalSubstitutionException("code-750", name: "name-201")
        #expect(item.status == Pharmacy.SeasonalSubstitutionExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newSeasonalSubstitutionException("code-750", name: "name-201")
        try item.moveTo(Pharmacy.SeasonalSubstitutionExceptionStatus.draining)
        #expect(item.status == Pharmacy.SeasonalSubstitutionExceptionStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newSeasonalSubstitutionException("code-750", name: "name-201")
        item.status = Pharmacy.SeasonalSubstitutionExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalSubstitutionExceptionStatus.idle) }
    }
}
