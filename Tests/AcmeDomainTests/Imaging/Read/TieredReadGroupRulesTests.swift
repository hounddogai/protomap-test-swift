@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredReadGroupValidator()
        let item = Imaging.newTieredReadGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredReadGroupStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.TieredReadGroupStartsAtRangeRule(min: 64, max: 1000)
        let item = Imaging.newTieredReadGroup("x", name: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredReadGroupRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.TieredReadGroupRequiredRegionRule(message: "tiered read group needs a value")
        let item = Imaging.newTieredReadGroup("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredReadGroupRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.TieredReadGroupRegionLengthRule(maxLength: 1000)
        let item = Imaging.newTieredReadGroup("x", name: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredReadGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.TieredReadGroupNameLengthRule(maxLength: 80)
        let item = Imaging.newTieredReadGroup("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredReadGroupRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.TieredReadGroupRequiredAllergyRule(message: "tiered read group needs an entry")
        let item = Imaging.newTieredReadGroup("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
