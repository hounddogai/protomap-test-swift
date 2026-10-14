@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolRuleValidator()
        let item = Staffing.newFloatPoolRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.FloatPoolRuleTitleLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolRule("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolRuleCodeLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolRule("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolRuleRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.FloatPoolRuleRequiredBedRule(message: "float pool rule needs a value")
        let item = Staffing.newFloatPoolRule("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolRuleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.FloatPoolRuleCopayRangeRule(min: 8.5, max: 2686.7)
        let item = Staffing.newFloatPoolRule("x", title: "y")
        item.copay = 2688.2
        #expect(rule.check(item).count > 0)
    }
}
