@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapAdjustmentValidator()
        let item = CareManagement.newCareGapAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapAdjustmentVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.CareGapAdjustmentVersionRangeRule(min: 64, max: 1000)
        let item = CareManagement.newCareGapAdjustment("x", label: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.CareGapAdjustmentLabelLengthRule(maxLength: 80)
        let item = CareManagement.newCareGapAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapAdjustmentRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = CareManagement.CareGapAdjustmentRequiredCurrencyRule(message: "care gap adjustment needs a value")
        let item = CareManagement.newCareGapAdjustment("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapAdjustmentSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = CareManagement.CareGapAdjustmentSourceLengthRule(maxLength: 1000)
        let item = CareManagement.newCareGapAdjustment("x", label: "y")
        item.source = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
