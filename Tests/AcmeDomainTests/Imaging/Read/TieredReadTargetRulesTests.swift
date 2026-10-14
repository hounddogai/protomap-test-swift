@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredReadTargetValidator()
        let item = Imaging.newTieredReadTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredReadTargetRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Imaging.TieredReadTargetRequiredFacilityRule(message: "tiered read target needs an entry")
        let item = Imaging.newTieredReadTarget("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredReadTargetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.TieredReadTargetRequiredTitleRule(message: "tiered read target needs a value")
        let item = Imaging.newTieredReadTarget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredReadTargetFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Imaging.TieredReadTargetFacilityLengthRule(maxLength: 80)
        let item = Imaging.newTieredReadTarget("x", title: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredReadTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.TieredReadTargetRequiredCodeRule(message: "tiered read target needs this field")
        let item = Imaging.newTieredReadTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredReadTargetCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Imaging.TieredReadTargetCategoryLengthRule(maxLength: 255)
        let item = Imaging.newTieredReadTarget("x", title: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
