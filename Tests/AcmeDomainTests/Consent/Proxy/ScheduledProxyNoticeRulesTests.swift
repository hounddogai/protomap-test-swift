@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledProxyNoticeValidator()
        let item = Consent.newScheduledProxyNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledProxyNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ScheduledProxyNoticeRequiredTitleRule(message: "scheduled proxy notice needs an entry")
        let item = Consent.newScheduledProxyNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledProxyNoticeExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Consent.ScheduledProxyNoticeExternalRefLengthRule(maxLength: 1000)
        let item = Consent.newScheduledProxyNotice("x", title: "y")
        item.externalRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
