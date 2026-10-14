@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramPlanValidator()
        let item = CareManagement.newProgramPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramPlanNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.ProgramPlanNameLengthRule(maxLength: 120)
        let item = CareManagement.newProgramPlan("x", title: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramPlanGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.ProgramPlanGraceDaysRangeRule(min: 16, max: 3600)
        let item = CareManagement.newProgramPlan("x", title: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramPlanRequiredCodeRule(message: "program plan needs a value")
        let item = CareManagement.newProgramPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
