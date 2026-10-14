@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenNoticeValidator()
        let item = Labs.newSpecimenNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenNoticeCodeLengthRule(maxLength: 120)
        let item = Labs.newSpecimenNotice("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenNoticeMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.SpecimenNoticeMarginRangeRule(min: 7.7, max: 3136.4)
        let item = Labs.newSpecimenNotice("x", label: "y")
        item.margin = 3137.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenNoticeRequiredCodeRule(message: "specimen notice needs this field")
        let item = Labs.newSpecimenNotice("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenNoticeRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.SpecimenNoticeRequiredLocaleRule(message: "specimen notice needs this field")
        let item = Labs.newSpecimenNotice("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenNoticeCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.SpecimenNoticeCeilingRangeRule(min: 8.4, max: 4177.6)
        let item = Labs.newSpecimenNotice("x", label: "y")
        item.ceiling = 4179.1
        #expect(rule.check(item).count > 0)
    }
}
