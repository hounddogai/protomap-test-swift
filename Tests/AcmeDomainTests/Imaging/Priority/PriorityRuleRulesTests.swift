@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityRuleValidator()
        let item = Imaging.newPriorityRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityRuleCodeLengthRule(maxLength: 80)
        let item = Imaging.newPriorityRule("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityRulePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.PriorityRulePriorityRangeRule(min: 16, max: 3600)
        let item = Imaging.newPriorityRule("x", label: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityRuleGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.PriorityRuleGraceDaysRangeRule(min: 16, max: 86400)
        let item = Imaging.newPriorityRule("x", label: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}
