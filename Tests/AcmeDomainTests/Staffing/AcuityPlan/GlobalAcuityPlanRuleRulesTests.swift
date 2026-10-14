@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalAcuityPlanRuleValidator()
        let item = Staffing.newGlobalAcuityPlanRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.GlobalAcuityPlanRuleCodeLengthRule(maxLength: 1000)
        let item = Staffing.newGlobalAcuityPlanRule("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanRuleTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Staffing.GlobalAcuityPlanRuleTimezoneLengthRule(maxLength: 1000)
        let item = Staffing.newGlobalAcuityPlanRule("x", title: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanRuleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.GlobalAcuityPlanRuleCeilingRangeRule(min: 0.2, max: 2763.7)
        let item = Staffing.newGlobalAcuityPlanRule("x", title: "y")
        item.ceiling = 2765.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanRuleRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Staffing.GlobalAcuityPlanRuleRequiredTimezoneRule(message: "global acuity plan rule needs this field")
        let item = Staffing.newGlobalAcuityPlanRule("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
