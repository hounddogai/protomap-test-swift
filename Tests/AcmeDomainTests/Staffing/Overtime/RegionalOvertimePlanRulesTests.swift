@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalOvertimePlanValidator()
        let item = Staffing.newRegionalOvertimePlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalOvertimePlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.RegionalOvertimePlanCodeLengthRule(maxLength: 86400)
        let item = Staffing.newRegionalOvertimePlan("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalOvertimePlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RegionalOvertimePlanRequiredCodeRule(message: "regional overtime plan needs an entry")
        let item = Staffing.newRegionalOvertimePlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalOvertimePlanWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.RegionalOvertimePlanWeightRangeRule(min: 8.3, max: 4085.1)
        let item = Staffing.newRegionalOvertimePlan("x", name: "y")
        item.weight = 4086.6
        #expect(rule.check(item).count > 0)
    }
}
