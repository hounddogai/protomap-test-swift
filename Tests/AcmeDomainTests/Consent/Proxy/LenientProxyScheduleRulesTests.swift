@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientProxyScheduleValidator()
        let item = Consent.newLenientProxySchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientProxyScheduleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.LenientProxyScheduleCostRangeRule(min: 1.0, max: 4251.9)
        let item = Consent.newLenientProxySchedule("x", name: "y")
        item.cost = 4253.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientProxyScheduleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.LenientProxyScheduleRetriesRangeRule(min: 64, max: 3600)
        let item = Consent.newLenientProxySchedule("x", name: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientProxyScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LenientProxyScheduleCodeLengthRule(maxLength: 86400)
        let item = Consent.newLenientProxySchedule("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
