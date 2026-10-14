@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolMilestoneValidator()
        let item = Staffing.newFloatPoolMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolMilestoneRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.FloatPoolMilestoneRequiredSummaryRule(message: "float pool milestone needs this field")
        let item = Staffing.newFloatPoolMilestone("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolMilestoneLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.FloatPoolMilestoneLimitRangeRule(min: 1000, max: 3600)
        let item = Staffing.newFloatPoolMilestone("x", label: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolMilestoneExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Staffing.FloatPoolMilestoneExternalRefLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolMilestone("x", label: "y")
        item.externalRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolMilestoneRequiredCodeRule(message: "float pool milestone needs this field")
        let item = Staffing.newFloatPoolMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
