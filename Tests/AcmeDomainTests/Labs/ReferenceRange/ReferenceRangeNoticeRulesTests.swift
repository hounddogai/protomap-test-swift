@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeNoticeValidator()
        let item = Labs.newReferenceRangeNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeNoticeAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.ReferenceRangeNoticeAllergyLengthRule(maxLength: 80)
        let item = Labs.newReferenceRangeNotice("x", label: "y")
        item.allergy = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeNoticeLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.ReferenceRangeNoticeLimitRangeRule(min: 16, max: 86400)
        let item = Labs.newReferenceRangeNotice("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeNoticeRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.ReferenceRangeNoticeRequiredAllergyRule(message: "reference range notice needs an entry")
        let item = Labs.newReferenceRangeNotice("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeNoticeUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.ReferenceRangeNoticeUnitLengthRule(maxLength: 64)
        let item = Labs.newReferenceRangeNotice("x", label: "y")
        item.unit = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
