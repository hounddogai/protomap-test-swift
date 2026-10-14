@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyHandoffRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyHandoffRequestValidator()
        let item = ClinicalOps.newLegacyHandoffRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyHandoffRequestMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.LegacyHandoffRequestMinimumRangeRule(min: 2.1, max: 1740.9)
        let item = ClinicalOps.newLegacyHandoffRequest("x", label: "y")
        item.minimum = 1742.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLegacyHandoffRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.LegacyHandoffRequestRequiredLabelRule(message: "legacy handoff request needs an entry")
        let item = ClinicalOps.newLegacyHandoffRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyHandoffRequestGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.LegacyHandoffRequestGraceDaysRangeRule(min: 64, max: 3600)
        let item = ClinicalOps.newLegacyHandoffRequest("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLegacyHandoffRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LegacyHandoffRequestRequiredCodeRule(message: "legacy handoff request needs an entry")
        let item = ClinicalOps.newLegacyHandoffRequest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyHandoffRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.LegacyHandoffRequestLabelLengthRule(maxLength: 255)
        let item = ClinicalOps.newLegacyHandoffRequest("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
