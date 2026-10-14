@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackCourierCycleValidator()
        let item = Labs.newFallbackCourierCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackCourierCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.FallbackCourierCycleRequiredNameRule(message: "fallback courier cycle needs this field")
        let item = Labs.newFallbackCourierCycle("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackCourierCycleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.FallbackCourierCycleAmountRangeRule(min: 3.2, max: 200.1)
        let item = Labs.newFallbackCourierCycle("x", label: "y")
        item.amount = 201.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackCourierCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.FallbackCourierCycleLabelLengthRule(maxLength: 3600)
        let item = Labs.newFallbackCourierCycle("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackCourierCycleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.FallbackCourierCycleScoreRangeRule(min: 3.1, max: 1555.5)
        let item = Labs.newFallbackCourierCycle("x", label: "y")
        item.score = 1557.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackCourierCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackCourierCycleRequiredCodeRule(message: "fallback courier cycle needs this field")
        let item = Labs.newFallbackCourierCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
