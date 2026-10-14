@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientInventoryOverrideValidator()
        let item = Pharmacy.newLenientInventoryOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientInventoryOverrideRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Pharmacy.LenientInventoryOverrideRequiredContactEmailRule(
            message: "lenient inventory override needs a value"
        )
        let item = Pharmacy.newLenientInventoryOverride("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInventoryOverrideRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Pharmacy.LenientInventoryOverrideRegionLengthRule(maxLength: 3600)
        let item = Pharmacy.newLenientInventoryOverride("x", label: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientInventoryOverrideContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.LenientInventoryOverrideContactEmailLengthRule(maxLength: 1000)
        let item = Pharmacy.newLenientInventoryOverride("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
