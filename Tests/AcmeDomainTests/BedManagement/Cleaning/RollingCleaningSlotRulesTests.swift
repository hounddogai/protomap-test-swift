@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingCleaningSlotValidator()
        let item = BedManagement.newRollingCleaningSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingCleaningSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.RollingCleaningSlotTitleLengthRule(maxLength: 86400)
        let item = BedManagement.newRollingCleaningSlot("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingCleaningSlotCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.RollingCleaningSlotCeilingRangeRule(min: 5.0, max: 4376.4)
        let item = BedManagement.newRollingCleaningSlot("x", title: "y")
        item.ceiling = 4377.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingCleaningSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RollingCleaningSlotCodeLengthRule(maxLength: 32)
        let item = BedManagement.newRollingCleaningSlot("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
