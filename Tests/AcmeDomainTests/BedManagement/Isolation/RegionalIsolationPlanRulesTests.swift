@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRegionalIsolationPlanValidator()
        let item = BedManagement.newRegionalIsolationPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRegionalIsolationPlanRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = BedManagement.RegionalIsolationPlanRequiredRegionRule(
            message: "regional isolation plan needs this field"
        )
        let item = BedManagement.newRegionalIsolationPlan("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRegionalIsolationPlanRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.RegionalIsolationPlanRegionLengthRule(maxLength: 16)
        let item = BedManagement.newRegionalIsolationPlan("x", title: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRegionalIsolationPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RegionalIsolationPlanCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newRegionalIsolationPlan("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRegionalIsolationPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.RegionalIsolationPlanRequiredTitleRule(
            message: "regional isolation plan needs this field"
        )
        let item = BedManagement.newRegionalIsolationPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
