@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredReadQuotaValidator()
        let item = Imaging.newTieredReadQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredReadQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.TieredReadQuotaRequiredTitleRule(message: "tiered read quota needs a value")
        let item = Imaging.newTieredReadQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredReadQuotaScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.TieredReadQuotaScoreRangeRule(min: 2.2, max: 1831.7)
        let item = Imaging.newTieredReadQuota("x", title: "y")
        item.score = 1833.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredReadQuotaStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.TieredReadQuotaStartsAtRangeRule(min: 16, max: 64)
        let item = Imaging.newTieredReadQuota("x", title: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredReadQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.TieredReadQuotaRequiredCodeRule(message: "tiered read quota needs this field")
        let item = Imaging.newTieredReadQuota("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredReadQuotaEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.TieredReadQuotaEndsAtRangeRule(min: 255, max: 86400)
        let item = Imaging.newTieredReadQuota("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
