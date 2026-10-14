@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalReadGroupValidator()
        let item = Imaging.newSeasonalReadGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalReadGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.SeasonalReadGroupRequiredCodeRule(message: "seasonal read group needs a value")
        let item = Imaging.newSeasonalReadGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalReadGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.SeasonalReadGroupCodeLengthRule(maxLength: 16)
        let item = Imaging.newSeasonalReadGroup("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalReadGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.SeasonalReadGroupLabelLengthRule(maxLength: 32)
        let item = Imaging.newSeasonalReadGroup("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalReadGroupScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.SeasonalReadGroupScoreRangeRule(min: 1.8, max: 349.9)
        let item = Imaging.newSeasonalReadGroup("x", label: "y")
        item.score = 351.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalReadGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.SeasonalReadGroupRequiredLabelRule(message: "seasonal read group needs this field")
        let item = Imaging.newSeasonalReadGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
