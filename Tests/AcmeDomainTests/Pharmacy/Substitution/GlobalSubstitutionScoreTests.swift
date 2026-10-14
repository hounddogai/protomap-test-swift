@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalSubstitutionScoreTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newGlobalSubstitutionScore("code-656", title: "title-465")
        #expect(item.status == Pharmacy.GlobalSubstitutionScoreStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newGlobalSubstitutionScore("code-656", title: "title-465")
        try item.moveTo(Pharmacy.GlobalSubstitutionScoreStatus.warming)
        #expect(item.status == Pharmacy.GlobalSubstitutionScoreStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newGlobalSubstitutionScore("code-656", title: "title-465")
        item.status = Pharmacy.GlobalSubstitutionScoreStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalSubstitutionScoreStatus.idle) }
    }
}
