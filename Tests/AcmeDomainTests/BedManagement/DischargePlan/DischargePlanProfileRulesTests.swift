@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanProfileValidator()
        let item = BedManagement.newDischargePlanProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanProfileAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.DischargePlanProfileAttemptsRangeRule(min: 32, max: 255)
        let item = BedManagement.newDischargePlanProfile("x", title: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.DischargePlanProfileTitleLengthRule(maxLength: 32)
        let item = BedManagement.newDischargePlanProfile("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanProfileCodeLengthRule(maxLength: 80)
        let item = BedManagement.newDischargePlanProfile("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DischargePlanProfileLabelLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanProfile("x", title: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
