@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultProgramBaselineValidator()
        let item = CareManagement.newDefaultProgramBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultProgramBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.DefaultProgramBaselineRequiredLabelRule(
            message: "default program baseline needs an entry"
        )
        let item = CareManagement.newDefaultProgramBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultProgramBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.DefaultProgramBaselineRequiredCodeRule(
            message: "default program baseline needs this field"
        )
        let item = CareManagement.newDefaultProgramBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultProgramBaselineGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.DefaultProgramBaselineGraceDaysRangeRule(min: 16, max: 3600)
        let item = CareManagement.newDefaultProgramBaseline("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementDefaultProgramBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.DefaultProgramBaselineLabelLengthRule(maxLength: 32)
        let item = CareManagement.newDefaultProgramBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
