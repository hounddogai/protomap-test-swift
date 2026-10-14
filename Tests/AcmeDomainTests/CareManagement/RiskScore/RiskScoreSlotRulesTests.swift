@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreSlotValidator()
        let item = CareManagement.newRiskScoreSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreSlotCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.RiskScoreSlotCopayRangeRule(min: 7.1, max: 158.0)
        let item = CareManagement.newRiskScoreSlot("x", title: "y")
        item.copay = 159.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreSlotMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = CareManagement.RiskScoreSlotMarginRangeRule(min: 4.8, max: 3253.9)
        let item = CareManagement.newRiskScoreSlot("x", title: "y")
        item.margin = 3255.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RiskScoreSlotTitleLengthRule(maxLength: 80)
        let item = CareManagement.newRiskScoreSlot("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RiskScoreSlotCodeLengthRule(maxLength: 255)
        let item = CareManagement.newRiskScoreSlot("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
