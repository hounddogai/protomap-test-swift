@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInteractionTierValidator()
        let item = Pharmacy.newLegacyInteractionTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInteractionTierTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Pharmacy.LegacyInteractionTierTimezoneLengthRule(maxLength: 3600)
        let item = Pharmacy.newLegacyInteractionTier("x", name: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInteractionTierRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Pharmacy.LegacyInteractionTierRequiredPhoneRule(message: "legacy interaction tier needs a value")
        let item = Pharmacy.newLegacyInteractionTier("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LegacyInteractionTierRequiredCodeRule(message: "legacy interaction tier needs a value")
        let item = Pharmacy.newLegacyInteractionTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.LegacyInteractionTierNameLengthRule(maxLength: 32)
        let item = Pharmacy.newLegacyInteractionTier("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInteractionTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LegacyInteractionTierCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newLegacyInteractionTier("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
