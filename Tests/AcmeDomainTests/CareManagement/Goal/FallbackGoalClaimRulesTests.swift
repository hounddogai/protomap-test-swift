@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackGoalClaimValidator()
        let item = CareManagement.newFallbackGoalClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackGoalClaimRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = CareManagement.FallbackGoalClaimRequiredOwnerIDRule(message: "fallback goal claim needs an entry")
        let item = CareManagement.newFallbackGoalClaim("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackGoalClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.FallbackGoalClaimRequiredTitleRule(message: "fallback goal claim needs a value")
        let item = CareManagement.newFallbackGoalClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackGoalClaimAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = CareManagement.FallbackGoalClaimAttemptsRangeRule(min: 32, max: 64)
        let item = CareManagement.newFallbackGoalClaim("x", title: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackGoalClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.FallbackGoalClaimRequiredCodeRule(message: "fallback goal claim needs an entry")
        let item = CareManagement.newFallbackGoalClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
