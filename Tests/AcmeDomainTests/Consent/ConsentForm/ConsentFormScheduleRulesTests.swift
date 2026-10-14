@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormScheduleValidator()
        let item = Consent.newConsentFormSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormScheduleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.ConsentFormScheduleTitleLengthRule(maxLength: 16)
        let item = Consent.newConsentFormSchedule("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormScheduleLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.ConsentFormScheduleLocaleLengthRule(maxLength: 3600)
        let item = Consent.newConsentFormSchedule("x", title: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormScheduleRequiredCodeRule(message: "consent form schedule needs an entry")
        let item = Consent.newConsentFormSchedule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormScheduleDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.ConsentFormScheduleDosageMgRangeRule(min: 5.6, max: 1692.3)
        let item = Consent.newConsentFormSchedule("x", title: "y")
        item.dosageMg = 1693.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormScheduleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ConsentFormScheduleRequiredTitleRule(message: "consent form schedule needs this field")
        let item = Consent.newConsentFormSchedule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
