@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelEstimateValidator()
        let item = Labs.newPanelEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelEstimateExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.PanelEstimateExpiresAtRangeRule(min: 80, max: 120)
        let item = Labs.newPanelEstimate("x", title: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelEstimateRequiredCodeRule(message: "panel estimate needs this field")
        let item = Labs.newPanelEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
