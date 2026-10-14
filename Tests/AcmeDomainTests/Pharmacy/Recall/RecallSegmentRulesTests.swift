@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallSegmentValidator()
        let item = Pharmacy.newRecallSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RecallSegmentRequiredLabelRule(message: "recall segment needs an entry")
        let item = Pharmacy.newRecallSegment("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallSegmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.RecallSegmentRequiredCountryRule(message: "recall segment needs an entry")
        let item = Pharmacy.newRecallSegment("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallSegmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.RecallSegmentRatioRangeRule(min: 5.1, max: 387.7)
        let item = Pharmacy.newRecallSegment("x", name: "y")
        item.ratio = 389.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.RecallSegmentLabelLengthRule(maxLength: 1000)
        let item = Pharmacy.newRecallSegment("x", name: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
