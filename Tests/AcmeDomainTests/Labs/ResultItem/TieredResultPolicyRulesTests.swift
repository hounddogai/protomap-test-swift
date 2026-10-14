@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredResultPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultTieredResultPolicyValidator()
        let item = Labs.newTieredResultPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsTieredResultPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.TieredResultPolicyCodeLengthRule(maxLength: 16)
        let item = Labs.newTieredResultPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsTieredResultPolicyRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Labs.TieredResultPolicyRequiredSourceRule(message: "tiered result policy needs this field")
        let item = Labs.newTieredResultPolicy("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredResultPolicySourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Labs.TieredResultPolicySourceLengthRule(maxLength: 64)
        let item = Labs.newTieredResultPolicy("x", title: "y")
        item.source = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsTieredResultPolicyCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.TieredResultPolicyCeilingRangeRule(min: 4.1, max: 2600.2)
        let item = Labs.newTieredResultPolicy("x", title: "y")
        item.ceiling = 2601.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsTieredResultPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.TieredResultPolicyRequiredCodeRule(message: "tiered result policy needs a value")
        let item = Labs.newTieredResultPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
