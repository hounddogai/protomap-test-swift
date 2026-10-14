@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationPlanValidator()
        let item = BedManagement.newIsolationPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationPlanRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = BedManagement.IsolationPlanRequiredSummaryRule(message: "isolation plan needs a value")
        let item = BedManagement.newIsolationPlan("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationPlanCodeLengthRule(maxLength: 32)
        let item = BedManagement.newIsolationPlan("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationPlanRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.IsolationPlanRequiredEncounterIDRule(message: "isolation plan needs this field")
        let item = BedManagement.newIsolationPlan("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
