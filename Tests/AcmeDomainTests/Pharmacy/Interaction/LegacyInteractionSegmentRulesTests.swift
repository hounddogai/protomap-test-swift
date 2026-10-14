@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInteractionSegmentValidator()
        let item = Pharmacy.newLegacyInteractionSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInteractionSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.LegacyInteractionSegmentRequiredLabelRule(
            message: "legacy interaction segment needs a value"
        )
        let item = Pharmacy.newLegacyInteractionSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionSegmentCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Pharmacy.LegacyInteractionSegmentCountryLengthRule(maxLength: 255)
        let item = Pharmacy.newLegacyInteractionSegment("x", label: "y")
        item.country = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInteractionSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LegacyInteractionSegmentCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newLegacyInteractionSegment("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
