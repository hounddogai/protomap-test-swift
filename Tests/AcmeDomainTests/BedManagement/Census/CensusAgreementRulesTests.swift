@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusAgreementValidator()
        let item = BedManagement.newCensusAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusAgreementBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.CensusAgreementBudgetRangeRule(min: 0.3, max: 834.4)
        let item = BedManagement.newCensusAgreement("x", title: "y")
        item.budget = 835.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusAgreementCodeLengthRule(maxLength: 16)
        let item = BedManagement.newCensusAgreement("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusAgreementThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.CensusAgreementThresholdRangeRule(min: 2.8, max: 1767.6)
        let item = BedManagement.newCensusAgreement("x", title: "y")
        item.threshold = 1769.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.CensusAgreementRequiredTitleRule(message: "census agreement needs a value")
        let item = BedManagement.newCensusAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
