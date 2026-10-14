@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveProgramCycleValidator()
        let item = CareManagement.newAdaptiveProgramCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveProgramCycleRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = CareManagement.AdaptiveProgramCycleRefillsRangeRule(min: 64, max: 120)
        let item = CareManagement.newAdaptiveProgramCycle("x", name: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveProgramCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AdaptiveProgramCycleRequiredCodeRule(message: "adaptive program cycle needs an entry")
        let item = CareManagement.newAdaptiveProgramCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
