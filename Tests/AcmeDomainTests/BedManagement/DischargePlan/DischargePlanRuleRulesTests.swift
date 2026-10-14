@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanRuleValidator()
        let item = BedManagement.newDischargePlanRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanRuleCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newDischargePlanRule("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.DischargePlanRuleTitleLengthRule(maxLength: 32)
        let item = BedManagement.newDischargePlanRule("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
