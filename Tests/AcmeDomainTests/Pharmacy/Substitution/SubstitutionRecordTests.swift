@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRecordTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newSubstitutionRecord("code-676", name: "name-856")
        #expect(item.status == Pharmacy.SubstitutionRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newSubstitutionRecord("code-676", name: "name-856")
        try item.moveTo(Pharmacy.SubstitutionRecordStatus.expired)
        #expect(item.status == Pharmacy.SubstitutionRecordStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newSubstitutionRecord("code-676", name: "name-856")
        item.status = Pharmacy.SubstitutionRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionRecordStatus.requested) }
    }
}
