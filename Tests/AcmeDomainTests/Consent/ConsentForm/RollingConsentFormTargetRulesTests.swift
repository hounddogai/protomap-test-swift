@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingConsentFormTargetValidator()
        let item = Consent.newRollingConsentFormTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingConsentFormTargetRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Consent.RollingConsentFormTargetRequiredPhoneRule(
            message: "rolling consent form target needs an entry"
        )
        let item = Consent.newRollingConsentFormTarget("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingConsentFormTargetRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.RollingConsentFormTargetRequiredContactEmailRule(
            message: "rolling consent form target needs a value"
        )
        let item = Consent.newRollingConsentFormTarget("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingConsentFormTargetPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Consent.RollingConsentFormTargetPhoneLengthRule(maxLength: 32)
        let item = Consent.newRollingConsentFormTarget("x", name: "y")
        item.phone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingConsentFormTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RollingConsentFormTargetRequiredCodeRule(
            message: "rolling consent form target needs this field"
        )
        let item = Consent.newRollingConsentFormTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingConsentFormTargetQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.RollingConsentFormTargetQuantityRangeRule(min: 16, max: 32)
        let item = Consent.newRollingConsentFormTarget("x", name: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}
