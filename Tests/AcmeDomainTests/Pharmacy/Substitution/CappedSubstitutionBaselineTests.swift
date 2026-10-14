@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedSubstitutionBaselineTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newCappedSubstitutionBaseline("code-507", name: "name-945")
        #expect(item.status == Pharmacy.CappedSubstitutionBaselineStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newCappedSubstitutionBaseline("code-507", name: "name-945")
        try item.moveTo(Pharmacy.CappedSubstitutionBaselineStatus.warming)
        #expect(item.status == Pharmacy.CappedSubstitutionBaselineStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newCappedSubstitutionBaseline("code-507", name: "name-945")
        item.status = Pharmacy.CappedSubstitutionBaselineStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedSubstitutionBaselineStatus.idle) }
    }
}
