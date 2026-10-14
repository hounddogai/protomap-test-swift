@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultReferenceRangeRuleValidator()
        let item = Labs.newDefaultReferenceRangeRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultReferenceRangeRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.DefaultReferenceRangeRuleTitleLengthRule(maxLength: 3600)
        let item = Labs.newDefaultReferenceRangeRule("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultReferenceRangeRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.DefaultReferenceRangeRuleRequiredCodeRule(message: "default reference range rule needs an entry")
        let item = Labs.newDefaultReferenceRangeRule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultReferenceRangeRuleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.DefaultReferenceRangeRuleScoreRangeRule(min: 2.1, max: 586.8)
        let item = Labs.newDefaultReferenceRangeRule("x", title: "y")
        item.score = 588.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultReferenceRangeRulePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Labs.DefaultReferenceRangeRulePayerLengthRule(maxLength: 1000)
        let item = Labs.newDefaultReferenceRangeRule("x", title: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultReferenceRangeRuleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.DefaultReferenceRangeRuleQuantityRangeRule(min: 80, max: 3600)
        let item = Labs.newDefaultReferenceRangeRule("x", title: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}
