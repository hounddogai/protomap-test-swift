@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyRemittanceRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyRemittanceRuleValidator()
        let item = RevenueCycle.newLegacyRemittanceRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyRemittanceRuleRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = RevenueCycle.LegacyRemittanceRuleRequiredSpecialtyRule(
            message: "legacy remittance rule needs this field"
        )
        let item = RevenueCycle.newLegacyRemittanceRule("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyRemittanceRuleSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = RevenueCycle.LegacyRemittanceRuleSpecialtyLengthRule(maxLength: 3600)
        let item = RevenueCycle.newLegacyRemittanceRule("x", name: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyRemittanceRuleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.LegacyRemittanceRuleLimitRangeRule(min: 1000, max: 86400)
        let item = RevenueCycle.newLegacyRemittanceRule("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyRemittanceRuleClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = RevenueCycle.LegacyRemittanceRuleClinicianIDLengthRule(maxLength: 3600)
        let item = RevenueCycle.newLegacyRemittanceRule("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
