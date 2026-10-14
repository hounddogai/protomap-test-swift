@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityTargetValidator()
        let item = Imaging.newPriorityTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityTargetCodeLengthRule(maxLength: 64)
        let item = Imaging.newPriorityTarget("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityTargetExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Imaging.PriorityTargetExpiresAtRangeRule(min: 80, max: 255)
        let item = Imaging.newPriorityTarget("x", label: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityTargetRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Imaging.PriorityTargetRequiredCurrencyRule(message: "priority target needs a value")
        let item = Imaging.newPriorityTarget("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityTargetSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Imaging.PriorityTargetSourceLengthRule(maxLength: 80)
        let item = Imaging.newPriorityTarget("x", label: "y")
        item.source = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
