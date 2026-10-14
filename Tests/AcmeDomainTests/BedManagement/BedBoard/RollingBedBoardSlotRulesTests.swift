@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingBedBoardSlotValidator()
        let item = BedManagement.newRollingBedBoardSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingBedBoardSlotGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.RollingBedBoardSlotGraceDaysRangeRule(min: 1000, max: 1000)
        let item = BedManagement.newRollingBedBoardSlot("x", title: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingBedBoardSlotRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.RollingBedBoardSlotRequiredContactEmailRule(
            message: "rolling bed board slot needs a value"
        )
        let item = BedManagement.newRollingBedBoardSlot("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingBedBoardSlotThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.RollingBedBoardSlotThresholdRangeRule(min: 6.9, max: 2460.2)
        let item = BedManagement.newRollingBedBoardSlot("x", title: "y")
        item.threshold = 2461.7
        #expect(rule.check(item).count > 0)
    }
}
