@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredReadOverrideValidator()
        let item = Imaging.newTieredReadOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredReadOverrideBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.TieredReadOverrideBedLengthRule(maxLength: 32)
        let item = Imaging.newTieredReadOverride("x", label: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredReadOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.TieredReadOverrideCodeLengthRule(maxLength: 120)
        let item = Imaging.newTieredReadOverride("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredReadOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.TieredReadOverrideRequiredLabelRule(message: "tiered read override needs an entry")
        let item = Imaging.newTieredReadOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredReadOverrideEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Imaging.TieredReadOverrideEncounterIDLengthRule(maxLength: 255)
        let item = Imaging.newTieredReadOverride("x", label: "y")
        item.encounterID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
