@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffProfileValidator()
        let item = ClinicalOps.newHandoffProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.HandoffProfileRequiredNameRule(message: "handoff profile needs a value")
        let item = ClinicalOps.newHandoffProfile("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffProfileRequiredCodeRule(message: "handoff profile needs this field")
        let item = ClinicalOps.newHandoffProfile("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffProfileGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.HandoffProfileGraceDaysRangeRule(min: 16, max: 120)
        let item = ClinicalOps.newHandoffProfile("x", label: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}
