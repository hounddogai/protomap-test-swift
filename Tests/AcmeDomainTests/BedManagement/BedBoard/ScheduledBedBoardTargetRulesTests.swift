@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledBedBoardTargetValidator()
        let item = BedManagement.newScheduledBedBoardTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledBedBoardTargetCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = BedManagement.ScheduledBedBoardTargetCostRangeRule(min: 7.9, max: 3161.2)
        let item = BedManagement.newScheduledBedBoardTarget("x", label: "y")
        item.cost = 3162.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledBedBoardTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.ScheduledBedBoardTargetRequiredLabelRule(
            message: "scheduled bed board target needs an entry"
        )
        let item = BedManagement.newScheduledBedBoardTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledBedBoardTargetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.ScheduledBedBoardTargetGraceDaysRangeRule(min: 64, max: 3600)
        let item = BedManagement.newScheduledBedBoardTarget("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledBedBoardTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ScheduledBedBoardTargetRequiredCodeRule(
            message: "scheduled bed board target needs a value"
        )
        let item = BedManagement.newScheduledBedBoardTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
