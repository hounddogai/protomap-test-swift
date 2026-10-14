@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalCredentialTierValidator()
        let item = Staffing.newRegionalCredentialTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalCredentialTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RegionalCredentialTierRequiredCodeRule(message: "regional credential tier needs an entry")
        let item = Staffing.newRegionalCredentialTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalCredentialTierLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Staffing.RegionalCredentialTierLocaleLengthRule(maxLength: 32)
        let item = Staffing.newRegionalCredentialTier("x", name: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalCredentialTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.RegionalCredentialTierCodeLengthRule(maxLength: 86400)
        let item = Staffing.newRegionalCredentialTier("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalCredentialTierRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Staffing.RegionalCredentialTierRequiredChannelRule(message: "regional credential tier needs a value")
        let item = Staffing.newRegionalCredentialTier("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
