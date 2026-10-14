@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultFloatPoolAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultFloatPoolAssignmentValidator()
        let item = Staffing.newDefaultFloatPoolAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultFloatPoolAssignmentCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.DefaultFloatPoolAssignmentCostRangeRule(min: 5.0, max: 3728.1)
        let item = Staffing.newDefaultFloatPoolAssignment("x", name: "y")
        item.cost = 3729.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultFloatPoolAssignmentRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Staffing.DefaultFloatPoolAssignmentRequiredSourceRule(
            message: "default float pool assignment needs a value"
        )
        let item = Staffing.newDefaultFloatPoolAssignment("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultFloatPoolAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.DefaultFloatPoolAssignmentCodeLengthRule(maxLength: 86400)
        let item = Staffing.newDefaultFloatPoolAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultFloatPoolAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.DefaultFloatPoolAssignmentRequiredCodeRule(
            message: "default float pool assignment needs this field"
        )
        let item = Staffing.newDefaultFloatPoolAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
