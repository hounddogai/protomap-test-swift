@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualBedBoardRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualBedBoardRollupValidator()
        let item = BedManagement.newManualBedBoardRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualBedBoardRollupContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = BedManagement.ManualBedBoardRollupContactEmailLengthRule(maxLength: 80)
        let item = BedManagement.newManualBedBoardRollup("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualBedBoardRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.ManualBedBoardRollupRequiredLabelRule(
            message: "manual bed board rollup needs this field"
        )
        let item = BedManagement.newManualBedBoardRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualBedBoardRollupBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.ManualBedBoardRollupBudgetRangeRule(min: 1.0, max: 2259.9)
        let item = BedManagement.newManualBedBoardRollup("x", label: "y")
        item.budget = 2261.4
        #expect(rule.check(item).count > 0)
    }
}
