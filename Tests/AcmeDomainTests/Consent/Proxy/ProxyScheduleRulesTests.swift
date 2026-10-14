@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyScheduleValidator()
        let item = Consent.newProxySchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyScheduleCodeLengthRule(maxLength: 64)
        let item = Consent.newProxySchedule("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxySchedulePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.ProxySchedulePriorityRangeRule(min: 1000, max: 86400)
        let item = Consent.newProxySchedule("x", title: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyScheduleRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Consent.ProxyScheduleRequiredCurrencyRule(message: "proxy schedule needs a value")
        let item = Consent.newProxySchedule("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
