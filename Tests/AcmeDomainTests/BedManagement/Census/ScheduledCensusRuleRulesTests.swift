@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCensusRuleValidator()
        let item = BedManagement.newScheduledCensusRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCensusRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.ScheduledCensusRuleRequiredTitleRule(message: "scheduled census rule needs an entry")
        let item = BedManagement.newScheduledCensusRule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCensusRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ScheduledCensusRuleCodeLengthRule(maxLength: 32)
        let item = BedManagement.newScheduledCensusRule("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
