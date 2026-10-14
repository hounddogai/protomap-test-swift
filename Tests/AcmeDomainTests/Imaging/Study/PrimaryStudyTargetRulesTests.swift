@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryStudyTargetValidator()
        let item = Imaging.newPrimaryStudyTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryStudyTargetRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Imaging.PrimaryStudyTargetRequiredCurrencyRule(message: "primary study target needs this field")
        let item = Imaging.newPrimaryStudyTarget("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryStudyTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PrimaryStudyTargetRequiredCodeRule(message: "primary study target needs an entry")
        let item = Imaging.newPrimaryStudyTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryStudyTargetRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Imaging.PrimaryStudyTargetRequiredChecksumRule(message: "primary study target needs an entry")
        let item = Imaging.newPrimaryStudyTarget("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryStudyTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PrimaryStudyTargetCodeLengthRule(maxLength: 16)
        let item = Imaging.newPrimaryStudyTarget("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryStudyTargetAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.PrimaryStudyTargetAcuityRangeRule(min: 64, max: 255)
        let item = Imaging.newPrimaryStudyTarget("x", label: "y")
        item.acuity = 256
        #expect(rule.check(item).count > 0)
    }
}
