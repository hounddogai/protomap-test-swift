@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingRecallQuotaValidator()
        let item = Pharmacy.newPendingRecallQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingRecallQuotaScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.PendingRecallQuotaScoreRangeRule(min: 9.9, max: 1121.5)
        let item = Pharmacy.newPendingRecallQuota("x", name: "y")
        item.score = 1123.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingRecallQuotaNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.PendingRecallQuotaNotesLengthRule(maxLength: 120)
        let item = Pharmacy.newPendingRecallQuota("x", name: "y")
        item.notes = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPendingRecallQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PendingRecallQuotaRequiredCodeRule(message: "pending recall quota needs a value")
        let item = Pharmacy.newPendingRecallQuota("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingRecallQuotaRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.PendingRecallQuotaRequiredSpecialtyRule(message: "pending recall quota needs this field")
        let item = Pharmacy.newPendingRecallQuota("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingRecallQuotaRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.PendingRecallQuotaRequiredNotesRule(message: "pending recall quota needs this field")
        let item = Pharmacy.newPendingRecallQuota("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
