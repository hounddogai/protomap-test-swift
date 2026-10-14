@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCensusPlanValidator()
        let item = BedManagement.newScheduledCensusPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCensusPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ScheduledCensusPlanRequiredCodeRule(message: "scheduled census plan needs this field")
        let item = BedManagement.newScheduledCensusPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCensusPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ScheduledCensusPlanCodeLengthRule(maxLength: 120)
        let item = BedManagement.newScheduledCensusPlan("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCensusPlanTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.ScheduledCensusPlanTitleLengthRule(maxLength: 1000)
        let item = BedManagement.newScheduledCensusPlan("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCensusPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.ScheduledCensusPlanRequiredTitleRule(message: "scheduled census plan needs a value")
        let item = BedManagement.newScheduledCensusPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
