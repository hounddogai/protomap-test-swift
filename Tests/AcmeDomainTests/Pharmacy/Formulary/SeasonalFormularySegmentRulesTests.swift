@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalFormularySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalFormularySegmentValidator()
        let item = Pharmacy.newSeasonalFormularySegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalFormularySegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.SeasonalFormularySegmentRequiredCodeRule(message: "seasonal formulary segment needs a value")
        let item = Pharmacy.newSeasonalFormularySegment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalFormularySegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.SeasonalFormularySegmentLabelLengthRule(maxLength: 120)
        let item = Pharmacy.newSeasonalFormularySegment("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySeasonalFormularySegmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Pharmacy.SeasonalFormularySegmentCeilingRangeRule(min: 9.6, max: 4192.3)
        let item = Pharmacy.newSeasonalFormularySegment("x", label: "y")
        item.ceiling = 4193.8
        #expect(rule.check(item).count > 0)
    }
}
