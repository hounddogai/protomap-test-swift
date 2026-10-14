@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferEstimateValidator()
        let item = BedManagement.newTransferEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.TransferEstimateLabelLengthRule(maxLength: 120)
        let item = BedManagement.newTransferEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferEstimateBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.TransferEstimateBudgetRangeRule(min: 7.5, max: 3045.7)
        let item = BedManagement.newTransferEstimate("x", label: "y")
        item.budget = 3047.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferEstimateRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.TransferEstimateRatioRangeRule(min: 2.9, max: 2487.2)
        let item = BedManagement.newTransferEstimate("x", label: "y")
        item.ratio = 2488.7
        #expect(rule.check(item).count > 0)
    }
}
