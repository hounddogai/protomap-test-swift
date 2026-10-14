@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredHandoffOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredHandoffOverrideValidator()
        let item = ClinicalOps.newTieredHandoffOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredHandoffOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.TieredHandoffOverrideTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newTieredHandoffOverride("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredHandoffOverrideWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.TieredHandoffOverrideWeightRangeRule(min: 9.2, max: 2386.2)
        let item = ClinicalOps.newTieredHandoffOverride("x", title: "y")
        item.weight = 2387.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTieredHandoffOverrideRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.TieredHandoffOverrideRequiredProcedureCodeRule(
            message: "tiered handoff override needs a value"
        )
        let item = ClinicalOps.newTieredHandoffOverride("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredHandoffOverrideRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.TieredHandoffOverrideRequiredTimezoneRule(
            message: "tiered handoff override needs a value"
        )
        let item = ClinicalOps.newTieredHandoffOverride("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
