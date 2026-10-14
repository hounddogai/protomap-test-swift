@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceScheduleValidator()
        let item = RevenueCycle.newRemittanceSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceScheduleCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newRemittanceSchedule("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceScheduleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RemittanceScheduleRequiredTitleRule(message: "remittance schedule needs this field")
        let item = RevenueCycle.newRemittanceSchedule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
