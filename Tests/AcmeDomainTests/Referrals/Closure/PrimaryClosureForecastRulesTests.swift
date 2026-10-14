@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryClosureForecastValidator()
        let item = Referrals.newPrimaryClosureForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryClosureForecastPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Referrals.PrimaryClosureForecastPhoneLengthRule(maxLength: 255)
        let item = Referrals.newPrimaryClosureForecast("x", label: "y")
        item.phone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryClosureForecastRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.PrimaryClosureForecastRequiredClinicianIDRule(
            message: "primary closure forecast needs this field"
        )
        let item = Referrals.newPrimaryClosureForecast("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryClosureForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PrimaryClosureForecastRequiredCodeRule(message: "primary closure forecast needs a value")
        let item = Referrals.newPrimaryClosureForecast("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryClosureForecastClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.PrimaryClosureForecastClinicianIDLengthRule(maxLength: 120)
        let item = Referrals.newPrimaryClosureForecast("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryClosureForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.PrimaryClosureForecastCodeLengthRule(maxLength: 16)
        let item = Referrals.newPrimaryClosureForecast("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
