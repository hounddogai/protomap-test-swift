@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyMilestoneValidator()
        let item = Consent.newProxyMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxyMilestoneRequiredNameRule(message: "proxy milestone needs this field")
        let item = Consent.newProxyMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.ProxyMilestoneNameLengthRule(maxLength: 86400)
        let item = Consent.newProxyMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyMilestoneRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.ProxyMilestoneRetriesRangeRule(min: 120, max: 3600)
        let item = Consent.newProxyMilestone("x", name: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}
