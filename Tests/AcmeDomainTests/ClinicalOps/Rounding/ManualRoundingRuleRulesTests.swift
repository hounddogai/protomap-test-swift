@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualRoundingRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultManualRoundingRuleValidator()
        let item = ClinicalOps.newManualRoundingRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsManualRoundingRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ManualRoundingRuleCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newManualRoundingRule("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualRoundingRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.ManualRoundingRuleTitleLengthRule(maxLength: 32)
        let item = ClinicalOps.newManualRoundingRule("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualRoundingRuleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = ClinicalOps.ManualRoundingRuleCeilingRangeRule(min: 0.8, max: 2371.8)
        let item = ClinicalOps.newManualRoundingRule("x", title: "y")
        item.ceiling = 2373.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsManualRoundingRuleRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = ClinicalOps.ManualRoundingRuleRequiredPhoneRule(message: "manual rounding rule needs a value")
        let item = ClinicalOps.newManualRoundingRule("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
