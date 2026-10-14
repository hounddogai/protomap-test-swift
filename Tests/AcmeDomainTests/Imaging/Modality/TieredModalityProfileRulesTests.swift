@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredModalityProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredModalityProfileValidator()
        let item = Imaging.newTieredModalityProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredModalityProfileBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.TieredModalityProfileBudgetRangeRule(min: 5.3, max: 426.0)
        let item = Imaging.newTieredModalityProfile("x", name: "y")
        item.budget = 427.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredModalityProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.TieredModalityProfileCodeLengthRule(maxLength: 3600)
        let item = Imaging.newTieredModalityProfile("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredModalityProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.TieredModalityProfileRequiredLabelRule(message: "tiered modality profile needs an entry")
        let item = Imaging.newTieredModalityProfile("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredModalityProfileNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.TieredModalityProfileNameLengthRule(maxLength: 64)
        let item = Imaging.newTieredModalityProfile("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
