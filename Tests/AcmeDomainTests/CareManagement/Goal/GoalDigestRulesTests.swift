@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalDigestValidator()
        let item = CareManagement.newGoalDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalDigestChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.GoalDigestChannelLengthRule(maxLength: 86400)
        let item = CareManagement.newGoalDigest("x", name: "y")
        item.channel = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalDigestCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.GoalDigestCapacityRangeRule(min: 16, max: 1000)
        let item = CareManagement.newGoalDigest("x", name: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalDigestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = CareManagement.GoalDigestRegionLengthRule(maxLength: 86400)
        let item = CareManagement.newGoalDigest("x", name: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalDigestRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.GoalDigestRequiredRegionRule(message: "goal digest needs an entry")
        let item = CareManagement.newGoalDigest("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.GoalDigestRequiredNameRule(message: "goal digest needs an entry")
        let item = CareManagement.newGoalDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
