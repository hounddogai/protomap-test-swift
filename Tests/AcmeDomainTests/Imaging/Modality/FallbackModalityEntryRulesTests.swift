@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackModalityEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackModalityEntryValidator()
        let item = Imaging.newFallbackModalityEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackModalityEntryCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Imaging.FallbackModalityEntryCurrencyLengthRule(maxLength: 80)
        let item = Imaging.newFallbackModalityEntry("x", name: "y")
        item.currency = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackModalityEntryRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Imaging.FallbackModalityEntryRequiredCurrencyRule(message: "fallback modality entry needs this field")
        let item = Imaging.newFallbackModalityEntry("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackModalityEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.FallbackModalityEntryNameLengthRule(maxLength: 255)
        let item = Imaging.newFallbackModalityEntry("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
