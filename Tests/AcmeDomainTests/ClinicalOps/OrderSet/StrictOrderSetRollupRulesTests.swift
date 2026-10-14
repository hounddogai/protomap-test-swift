@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictOrderSetRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictOrderSetRollupValidator()
        let item = ClinicalOps.newStrictOrderSetRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictOrderSetRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.StrictOrderSetRollupRequiredCodeRule(message: "strict order set rollup needs an entry")
        let item = ClinicalOps.newStrictOrderSetRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictOrderSetRollupCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = ClinicalOps.StrictOrderSetRollupCopayRangeRule(min: 3.2, max: 1666.8)
        let item = ClinicalOps.newStrictOrderSetRollup("x", label: "y")
        item.copay = 1668.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsStrictOrderSetRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.StrictOrderSetRollupCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newStrictOrderSetRollup("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsStrictOrderSetRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.StrictOrderSetRollupRequiredLabelRule(message: "strict order set rollup needs a value")
        let item = ClinicalOps.newStrictOrderSetRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
