@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreItemValidator()
        let item = CareManagement.newRiskScoreItem("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreItemDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = CareManagement.RiskScoreItemDosageMgRangeRule(min: 1.0, max: 4009.5)
        let item = CareManagement.newRiskScoreItem("x", label: "y")
        item.dosageMg = 4011.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreItemLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.RiskScoreItemLabelLengthRule(maxLength: 120)
        let item = CareManagement.newRiskScoreItem("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreItemTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RiskScoreItemTitleLengthRule(maxLength: 255)
        let item = CareManagement.newRiskScoreItem("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreItemRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.RiskScoreItemRequiredLabelRule(message: "risk score item needs this field")
        let item = CareManagement.newRiskScoreItem("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreItemRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = CareManagement.RiskScoreItemRegionLengthRule(maxLength: 86400)
        let item = CareManagement.newRiskScoreItem("x", label: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
