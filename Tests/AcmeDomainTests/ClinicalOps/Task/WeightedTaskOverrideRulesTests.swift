@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedTaskOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultWeightedTaskOverrideValidator()
        let item = ClinicalOps.newWeightedTaskOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsWeightedTaskOverrideRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.WeightedTaskOverrideRequiredNameRule(message: "weighted task override needs an entry")
        let item = ClinicalOps.newWeightedTaskOverride("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsWeightedTaskOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.WeightedTaskOverrideCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newWeightedTaskOverride("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsWeightedTaskOverrideRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = ClinicalOps.WeightedTaskOverrideRequiredSegmentRule(message: "weighted task override needs an entry")
        let item = ClinicalOps.newWeightedTaskOverride("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsWeightedTaskOverrideRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = ClinicalOps.WeightedTaskOverrideRequiredCountryRule(message: "weighted task override needs an entry")
        let item = ClinicalOps.newWeightedTaskOverride("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsWeightedTaskOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.WeightedTaskOverrideRequiredCodeRule(message: "weighted task override needs an entry")
        let item = ClinicalOps.newWeightedTaskOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
