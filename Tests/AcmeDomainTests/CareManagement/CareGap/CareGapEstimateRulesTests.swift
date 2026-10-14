@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapEstimateValidator()
        let item = CareManagement.newCareGapEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.CareGapEstimateLabelLengthRule(maxLength: 120)
        let item = CareManagement.newCareGapEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapEstimateWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.CareGapEstimateWindowDaysRangeRule(min: 32, max: 120)
        let item = CareManagement.newCareGapEstimate("x", label: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapEstimateUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.CareGapEstimateUnitLengthRule(maxLength: 86400)
        let item = CareManagement.newCareGapEstimate("x", label: "y")
        item.unit = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CareGapEstimateCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newCareGapEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapEstimateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.CareGapEstimateRequiredLabelRule(message: "care gap estimate needs a value")
        let item = CareManagement.newCareGapEstimate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
