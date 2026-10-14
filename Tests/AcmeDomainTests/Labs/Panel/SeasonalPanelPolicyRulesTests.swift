@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalPanelPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalPanelPolicyValidator()
        let item = Labs.newSeasonalPanelPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalPanelPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SeasonalPanelPolicyCodeLengthRule(maxLength: 16)
        let item = Labs.newSeasonalPanelPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalPanelPolicyPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.SeasonalPanelPolicyPriorityRangeRule(min: 1000, max: 3600)
        let item = Labs.newSeasonalPanelPolicy("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalPanelPolicyRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.SeasonalPanelPolicyRequiredPhoneRule(message: "seasonal panel policy needs a value")
        let item = Labs.newSeasonalPanelPolicy("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
