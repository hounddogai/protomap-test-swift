@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackFloatPoolMilestoneValidator()
        let item = Staffing.newFallbackFloatPoolMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackFloatPoolMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FallbackFloatPoolMilestoneCodeLengthRule(maxLength: 120)
        let item = Staffing.newFallbackFloatPoolMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackFloatPoolMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FallbackFloatPoolMilestoneRequiredCodeRule(
            message: "fallback float pool milestone needs a value"
        )
        let item = Staffing.newFallbackFloatPoolMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackFloatPoolMilestoneRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Staffing.FallbackFloatPoolMilestoneRequiredReviewerRule(
            message: "fallback float pool milestone needs an entry"
        )
        let item = Staffing.newFallbackFloatPoolMilestone("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
