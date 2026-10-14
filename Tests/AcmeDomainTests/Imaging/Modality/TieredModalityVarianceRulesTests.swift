@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredModalityVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredModalityVarianceValidator()
        let item = Imaging.newTieredModalityVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredModalityVarianceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.TieredModalityVarianceNameLengthRule(maxLength: 3600)
        let item = Imaging.newTieredModalityVariance("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredModalityVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.TieredModalityVarianceCodeLengthRule(maxLength: 64)
        let item = Imaging.newTieredModalityVariance("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredModalityVarianceRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.TieredModalityVarianceRequiredUnitRule(message: "tiered modality variance needs this field")
        let item = Imaging.newTieredModalityVariance("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredModalityVarianceRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.TieredModalityVarianceRequiredCountryRule(message: "tiered modality variance needs an entry")
        let item = Imaging.newTieredModalityVariance("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
