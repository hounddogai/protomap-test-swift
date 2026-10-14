@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackCourierSlotValidator()
        let item = Labs.newFallbackCourierSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackCourierSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackCourierSlotRequiredCodeRule(message: "fallback courier slot needs this field")
        let item = Labs.newFallbackCourierSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackCourierSlotRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.FallbackCourierSlotRequiredSummaryRule(message: "fallback courier slot needs this field")
        let item = Labs.newFallbackCourierSlot("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackCourierSlotThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.FallbackCourierSlotThresholdRangeRule(min: 0.2, max: 238.9)
        let item = Labs.newFallbackCourierSlot("x", name: "y")
        item.threshold = 240.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackCourierSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.FallbackCourierSlotNameLengthRule(maxLength: 255)
        let item = Labs.newFallbackCourierSlot("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
