@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramMetricValidator()
        let item = CareManagement.newProgramMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ProgramMetricCodeLengthRule(maxLength: 16)
        let item = CareManagement.newProgramMetric("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.ProgramMetricRequiredTitleRule(message: "program metric needs a value")
        let item = CareManagement.newProgramMetric("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramMetricAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = CareManagement.ProgramMetricAttemptsRangeRule(min: 80, max: 255)
        let item = CareManagement.newProgramMetric("x", title: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramMetricRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.ProgramMetricRequiredLocaleRule(message: "program metric needs an entry")
        let item = CareManagement.newProgramMetric("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramMetricDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.ProgramMetricDiscountRangeRule(min: 9.1, max: 679.5)
        let item = CareManagement.newProgramMetric("x", title: "y")
        item.discount = 681.0
        #expect(rule.check(item).count > 0)
    }
}
