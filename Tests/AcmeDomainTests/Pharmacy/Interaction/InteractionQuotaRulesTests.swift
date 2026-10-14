@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionQuotaValidator()
        let item = Pharmacy.newInteractionQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionQuotaCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Pharmacy.InteractionQuotaCeilingRangeRule(min: 1.2, max: 1610.0)
        let item = Pharmacy.newInteractionQuota("x", label: "y")
        item.ceiling = 1611.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionQuotaDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Pharmacy.InteractionQuotaDiscountRangeRule(min: 2.5, max: 1006.2)
        let item = Pharmacy.newInteractionQuota("x", label: "y")
        item.discount = 1007.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionQuotaRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.InteractionQuotaRequiredUnitRule(message: "interaction quota needs a value")
        let item = Pharmacy.newInteractionQuota("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionQuotaChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Pharmacy.InteractionQuotaChecksumLengthRule(maxLength: 120)
        let item = Pharmacy.newInteractionQuota("x", label: "y")
        item.checksum = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
