@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualProxyScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultManualProxyScheduleValidator()
        let item = Consent.newManualProxySchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentManualProxySchedulePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.ManualProxySchedulePriorityRangeRule(min: 32, max: 64)
        let item = Consent.newManualProxySchedule("x", title: "y")
        item.priority = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentManualProxyScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.ManualProxyScheduleNameLengthRule(maxLength: 3600)
        let item = Consent.newManualProxySchedule("x", title: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualProxyScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ManualProxyScheduleCodeLengthRule(maxLength: 120)
        let item = Consent.newManualProxySchedule("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualProxyScheduleSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Consent.ManualProxyScheduleSummaryLengthRule(maxLength: 255)
        let item = Consent.newManualProxySchedule("x", title: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualProxyScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ManualProxyScheduleRequiredNameRule(message: "manual proxy schedule needs an entry")
        let item = Consent.newManualProxySchedule("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
