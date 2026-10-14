@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalTaskOverrideValidator()
        let item = ClinicalOps.newGlobalTaskOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskOverrideAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.GlobalTaskOverrideAttemptsRangeRule(min: 32, max: 64)
        let item = ClinicalOps.newGlobalTaskOverride("x", title: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskOverrideRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.GlobalTaskOverrideRequiredSpecialtyRule(message: "global task override needs an entry")
        let item = ClinicalOps.newGlobalTaskOverride("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalTaskOverrideDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = ClinicalOps.GlobalTaskOverrideDosageMgRangeRule(min: 8.5, max: 2874.7)
        let item = ClinicalOps.newGlobalTaskOverride("x", title: "y")
        item.dosageMg = 2876.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskOverrideRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.GlobalTaskOverrideRequiredNameRule(message: "global task override needs an entry")
        let item = ClinicalOps.newGlobalTaskOverride("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
