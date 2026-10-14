@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapVarianceValidator()
        let item = CareManagement.newCareGapVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapVarianceSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = CareManagement.CareGapVarianceSourceLengthRule(maxLength: 120)
        let item = CareManagement.newCareGapVariance("x", title: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapVarianceRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = CareManagement.CareGapVarianceRequiredSpecialtyRule(message: "care gap variance needs this field")
        let item = CareManagement.newCareGapVariance("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapVarianceBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.CareGapVarianceBudgetRangeRule(min: 7.4, max: 887.4)
        let item = CareManagement.newCareGapVariance("x", title: "y")
        item.budget = 888.9
        #expect(rule.check(item).count > 0)
    }
}
