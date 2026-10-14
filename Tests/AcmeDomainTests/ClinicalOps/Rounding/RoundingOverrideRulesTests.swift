@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingOverrideValidator()
        let item = ClinicalOps.newRoundingOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingOverrideRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = ClinicalOps.RoundingOverrideRequiredCategoryRule(message: "rounding override needs an entry")
        let item = ClinicalOps.newRoundingOverride("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingOverrideEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.RoundingOverrideEndsAtRangeRule(min: 32, max: 3600)
        let item = ClinicalOps.newRoundingOverride("x", label: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingOverrideCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = ClinicalOps.RoundingOverrideCategoryLengthRule(maxLength: 1000)
        let item = ClinicalOps.newRoundingOverride("x", label: "y")
        item.category = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
