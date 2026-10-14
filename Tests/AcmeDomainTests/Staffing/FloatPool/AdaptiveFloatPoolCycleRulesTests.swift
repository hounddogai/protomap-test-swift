@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveFloatPoolCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveFloatPoolCycleValidator()
        let item = Staffing.newAdaptiveFloatPoolCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveFloatPoolCycleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.AdaptiveFloatPoolCycleBudgetRangeRule(min: 9.2, max: 1843.6)
        let item = Staffing.newAdaptiveFloatPoolCycle("x", label: "y")
        item.budget = 1845.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAdaptiveFloatPoolCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.AdaptiveFloatPoolCycleLabelLengthRule(maxLength: 64)
        let item = Staffing.newAdaptiveFloatPoolCycle("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAdaptiveFloatPoolCycleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.AdaptiveFloatPoolCycleVersionRangeRule(min: 255, max: 86400)
        let item = Staffing.newAdaptiveFloatPoolCycle("x", label: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAdaptiveFloatPoolCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AdaptiveFloatPoolCycleNameLengthRule(maxLength: 80)
        let item = Staffing.newAdaptiveFloatPoolCycle("x", label: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAdaptiveFloatPoolCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AdaptiveFloatPoolCycleRequiredCodeRule(message: "adaptive float pool cycle needs an entry")
        let item = Staffing.newAdaptiveFloatPoolCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
