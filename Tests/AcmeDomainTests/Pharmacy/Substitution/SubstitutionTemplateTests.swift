@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionTemplateTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newSubstitutionTemplate("code-33", label: "label-553")
        #expect(item.status == Pharmacy.SubstitutionTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newSubstitutionTemplate("code-33", label: "label-553")
        try item.moveTo(Pharmacy.SubstitutionTemplateStatus.warming)
        #expect(item.status == Pharmacy.SubstitutionTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newSubstitutionTemplate("code-33", label: "label-553")
        item.status = Pharmacy.SubstitutionTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionTemplateStatus.idle) }
    }
}
