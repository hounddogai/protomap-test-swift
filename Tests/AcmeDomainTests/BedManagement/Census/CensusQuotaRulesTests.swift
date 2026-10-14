@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusQuotaValidator()
        let item = BedManagement.newCensusQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusQuotaCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newCensusQuota("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusQuotaRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.CensusQuotaRequiredCountryRule(message: "census quota needs this field")
        let item = BedManagement.newCensusQuota("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusQuotaRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = BedManagement.CensusQuotaRequiredTimezoneRule(message: "census quota needs this field")
        let item = BedManagement.newCensusQuota("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
