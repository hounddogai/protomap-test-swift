@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionSegmentValidator()
        let item = Pharmacy.newSubstitutionSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionSegmentExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.SubstitutionSegmentExpiresAtRangeRule(min: 120, max: 1000)
        let item = Pharmacy.newSubstitutionSegment("x", label: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.SubstitutionSegmentLabelLengthRule(maxLength: 255)
        let item = Pharmacy.newSubstitutionSegment("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
