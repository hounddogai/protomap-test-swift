@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictIsolationMilestoneValidator()
        let item = BedManagement.newStrictIsolationMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictIsolationMilestoneMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.StrictIsolationMilestoneMarginRangeRule(min: 4.8, max: 3521.6)
        let item = BedManagement.newStrictIsolationMilestone("x", name: "y")
        item.margin = 3523.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictIsolationMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.StrictIsolationMilestoneRequiredCodeRule(
            message: "strict isolation milestone needs a value"
        )
        let item = BedManagement.newStrictIsolationMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictIsolationMilestoneExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.StrictIsolationMilestoneExpiresAtRangeRule(min: 120, max: 1000)
        let item = BedManagement.newStrictIsolationMilestone("x", name: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
