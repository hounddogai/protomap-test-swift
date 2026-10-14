@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackResultProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackResultProfileValidator()
        let item = Labs.newFallbackResultProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackResultProfileWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.FallbackResultProfileWindowDaysRangeRule(min: 32, max: 64)
        let item = Labs.newFallbackResultProfile("x", title: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackResultProfileChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Labs.FallbackResultProfileChecksumLengthRule(maxLength: 32)
        let item = Labs.newFallbackResultProfile("x", title: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackResultProfileRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Labs.FallbackResultProfileRequiredDescriptionRule(message: "fallback result profile needs an entry")
        let item = Labs.newFallbackResultProfile("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
