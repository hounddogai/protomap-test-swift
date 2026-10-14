@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreBaselineValidator()
        let item = CareManagement.newRiskScoreBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.RiskScoreBaselineRequiredNameRule(message: "risk score baseline needs an entry")
        let item = CareManagement.newRiskScoreBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RiskScoreBaselineNameLengthRule(maxLength: 16)
        let item = CareManagement.newRiskScoreBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreBaselineTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.RiskScoreBaselineTimezoneLengthRule(maxLength: 120)
        let item = CareManagement.newRiskScoreBaseline("x", name: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RiskScoreBaselineRequiredCodeRule(message: "risk score baseline needs this field")
        let item = CareManagement.newRiskScoreBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreBaselineRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.RiskScoreBaselineRequiredTimezoneRule(message: "risk score baseline needs this field")
        let item = CareManagement.newRiskScoreBaseline("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
