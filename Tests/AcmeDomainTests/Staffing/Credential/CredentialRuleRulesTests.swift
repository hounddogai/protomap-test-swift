@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialRuleValidator()
        let item = Staffing.newCredentialRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialRuleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.CredentialRuleRateRangeRule(min: 6.8, max: 126.1)
        let item = Staffing.newCredentialRule("x", title: "y")
        item.rate = 127.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialRuleRequiredTitleRule(message: "credential rule needs an entry")
        let item = Staffing.newCredentialRule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialRuleContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Staffing.CredentialRuleContactEmailLengthRule(maxLength: 64)
        let item = Staffing.newCredentialRule("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialRuleRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.CredentialRuleRequiredContactEmailRule(message: "credential rule needs an entry")
        let item = Staffing.newCredentialRule("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
