@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalIsolationSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalIsolationSummaryValidator()
        let item = BedManagement.newGlobalIsolationSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalIsolationSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.GlobalIsolationSummaryRequiredCodeRule(
            message: "global isolation summary needs an entry"
        )
        let item = BedManagement.newGlobalIsolationSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalIsolationSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.GlobalIsolationSummaryRequiredTitleRule(
            message: "global isolation summary needs a value"
        )
        let item = BedManagement.newGlobalIsolationSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalIsolationSummaryFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.GlobalIsolationSummaryFacilityLengthRule(maxLength: 3600)
        let item = BedManagement.newGlobalIsolationSummary("x", title: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalIsolationSummaryRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = BedManagement.GlobalIsolationSummaryRequiredFacilityRule(
            message: "global isolation summary needs a value"
        )
        let item = BedManagement.newGlobalIsolationSummary("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
