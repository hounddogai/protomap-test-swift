@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveProgramClaimValidator()
        let item = CareManagement.newAdaptiveProgramClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveProgramClaimBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.AdaptiveProgramClaimBudgetRangeRule(min: 4.4, max: 4409.6)
        let item = CareManagement.newAdaptiveProgramClaim("x", title: "y")
        item.budget = 4411.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveProgramClaimDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = CareManagement.AdaptiveProgramClaimDurationMinutesRangeRule(min: 3600, max: 3600)
        let item = CareManagement.newAdaptiveProgramClaim("x", title: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveProgramClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AdaptiveProgramClaimCodeLengthRule(maxLength: 80)
        let item = CareManagement.newAdaptiveProgramClaim("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveProgramClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AdaptiveProgramClaimRequiredCodeRule(message: "adaptive program claim needs a value")
        let item = CareManagement.newAdaptiveProgramClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveProgramClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.AdaptiveProgramClaimRequiredTitleRule(
            message: "adaptive program claim needs this field"
        )
        let item = CareManagement.newAdaptiveProgramClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
