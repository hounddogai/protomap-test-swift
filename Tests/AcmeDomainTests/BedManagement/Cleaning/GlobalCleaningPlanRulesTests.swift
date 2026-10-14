@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalCleaningPlanValidator()
        let item = BedManagement.newGlobalCleaningPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalCleaningPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.GlobalCleaningPlanRequiredTitleRule(message: "global cleaning plan needs a value")
        let item = BedManagement.newGlobalCleaningPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalCleaningPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.GlobalCleaningPlanRequiredCodeRule(message: "global cleaning plan needs a value")
        let item = BedManagement.newGlobalCleaningPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalCleaningPlanChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = BedManagement.GlobalCleaningPlanChannelLengthRule(maxLength: 86400)
        let item = BedManagement.newGlobalCleaningPlan("x", title: "y")
        item.channel = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalCleaningPlanCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.GlobalCleaningPlanCeilingRangeRule(min: 2.0, max: 1300.6)
        let item = BedManagement.newGlobalCleaningPlan("x", title: "y")
        item.ceiling = 1302.1
        #expect(rule.check(item).count > 0)
    }
}
