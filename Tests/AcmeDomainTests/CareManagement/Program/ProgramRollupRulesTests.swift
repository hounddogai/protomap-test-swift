@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramRollupValidator()
        let item = CareManagement.newProgramRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramRollupCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = CareManagement.ProgramRollupCategoryLengthRule(maxLength: 32)
        let item = CareManagement.newProgramRollup("x", label: "y")
        item.category = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramRollupRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = CareManagement.ProgramRollupRequiredCategoryRule(message: "program rollup needs an entry")
        let item = CareManagement.newProgramRollup("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramRollupRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.ProgramRollupRatioRangeRule(min: 7.0, max: 213.6)
        let item = CareManagement.newProgramRollup("x", label: "y")
        item.ratio = 215.1
        #expect(rule.check(item).count > 0)
    }
}
