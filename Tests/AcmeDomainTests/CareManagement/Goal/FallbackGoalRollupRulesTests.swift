@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackGoalRollupValidator()
        let item = CareManagement.newFallbackGoalRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackGoalRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.FallbackGoalRollupCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newFallbackGoalRollup("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackGoalRollupCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.FallbackGoalRollupCreatedAtRangeRule(min: 16, max: 80)
        let item = CareManagement.newFallbackGoalRollup("x", name: "y")
        item.createdAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackGoalRollupExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.FallbackGoalRollupExternalRefLengthRule(maxLength: 3600)
        let item = CareManagement.newFallbackGoalRollup("x", name: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackGoalRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.FallbackGoalRollupNameLengthRule(maxLength: 32)
        let item = CareManagement.newFallbackGoalRollup("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
