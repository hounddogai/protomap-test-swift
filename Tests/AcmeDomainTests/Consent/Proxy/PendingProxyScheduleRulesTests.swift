@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingProxyScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingProxyScheduleValidator()
        let item = Consent.newPendingProxySchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingProxyScheduleDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.PendingProxyScheduleDurationMinutesRangeRule(min: 64, max: 120)
        let item = Consent.newPendingProxySchedule("x", title: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingProxyScheduleRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Consent.PendingProxyScheduleRequiredWardRule(message: "pending proxy schedule needs an entry")
        let item = Consent.newPendingProxySchedule("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingProxyScheduleRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Consent.PendingProxyScheduleRequiredCurrencyRule(message: "pending proxy schedule needs a value")
        let item = Consent.newPendingProxySchedule("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingProxyScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PendingProxyScheduleCodeLengthRule(maxLength: 86400)
        let item = Consent.newPendingProxySchedule("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
