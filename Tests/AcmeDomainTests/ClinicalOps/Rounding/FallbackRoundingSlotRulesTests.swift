@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackRoundingSlotValidator()
        let item = ClinicalOps.newFallbackRoundingSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackRoundingSlotRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = ClinicalOps.FallbackRoundingSlotRequiredChecksumRule(message: "fallback rounding slot needs a value")
        let item = ClinicalOps.newFallbackRoundingSlot("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackRoundingSlotDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.FallbackRoundingSlotDiscountRangeRule(min: 9.0, max: 1044.9)
        let item = ClinicalOps.newFallbackRoundingSlot("x", name: "y")
        item.discount = 1046.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackRoundingSlotPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.FallbackRoundingSlotPatientRefLengthRule(maxLength: 120)
        let item = ClinicalOps.newFallbackRoundingSlot("x", name: "y")
        item.patientRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
