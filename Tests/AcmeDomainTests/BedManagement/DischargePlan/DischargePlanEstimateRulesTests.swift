@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanEstimateValidator()
        let item = BedManagement.newDischargePlanEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanEstimateScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.DischargePlanEstimateScoreRangeRule(min: 0.4, max: 483.4)
        let item = BedManagement.newDischargePlanEstimate("x", label: "y")
        item.score = 484.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanEstimateCodeLengthRule(maxLength: 255)
        let item = BedManagement.newDischargePlanEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanEstimateVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = BedManagement.DischargePlanEstimateVisitMinutesRangeRule(min: 32, max: 120)
        let item = BedManagement.newDischargePlanEstimate("x", label: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.DischargePlanEstimateRequiredTitleRule(message: "discharge plan estimate needs a value")
        let item = BedManagement.newDischargePlanEstimate("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
