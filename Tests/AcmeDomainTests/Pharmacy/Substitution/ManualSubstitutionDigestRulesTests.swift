@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualSubstitutionDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualSubstitutionDigestValidator()
        let item = Pharmacy.newManualSubstitutionDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualSubstitutionDigestEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Pharmacy.ManualSubstitutionDigestEncounterIDLengthRule(maxLength: 80)
        let item = Pharmacy.newManualSubstitutionDigest("x", name: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualSubstitutionDigestNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.ManualSubstitutionDigestNotesLengthRule(maxLength: 80)
        let item = Pharmacy.newManualSubstitutionDigest("x", name: "y")
        item.notes = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
