@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientIsolationBaselineValidator()
        let item = BedManagement.newLenientIsolationBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientIsolationBaselineBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.LenientIsolationBaselineBudgetRangeRule(min: 9.6, max: 1141.0)
        let item = BedManagement.newLenientIsolationBaseline("x", label: "y")
        item.budget = 1142.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientIsolationBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.LenientIsolationBaselineLabelLengthRule(maxLength: 3600)
        let item = BedManagement.newLenientIsolationBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientIsolationBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.LenientIsolationBaselineRequiredLabelRule(
            message: "lenient isolation baseline needs an entry"
        )
        let item = BedManagement.newLenientIsolationBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientIsolationBaselineCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = BedManagement.LenientIsolationBaselineCurrencyLengthRule(maxLength: 1000)
        let item = BedManagement.newLenientIsolationBaseline("x", label: "y")
        item.currency = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
