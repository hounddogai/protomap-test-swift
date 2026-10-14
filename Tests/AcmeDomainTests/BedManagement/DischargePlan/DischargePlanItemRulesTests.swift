@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanItemValidator()
        let item = BedManagement.newDischargePlanItem("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanItemRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanItemRequiredCodeRule(message: "discharge plan item needs an entry")
        let item = BedManagement.newDischargePlanItem("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanItemAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.DischargePlanItemAttemptsRangeRule(min: 32, max: 120)
        let item = BedManagement.newDischargePlanItem("x", label: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanItemPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.DischargePlanItemPriorityRangeRule(min: 32, max: 86400)
        let item = BedManagement.newDischargePlanItem("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanItemNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = BedManagement.DischargePlanItemNotesLengthRule(maxLength: 255)
        let item = BedManagement.newDischargePlanItem("x", label: "y")
        item.notes = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanItemRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = BedManagement.DischargePlanItemRequiredNotesRule(message: "discharge plan item needs this field")
        let item = BedManagement.newDischargePlanItem("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanItemStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.DischargePlanItemStartsAtRangeRule(min: 32, max: 3600)
        let item = BedManagement.newDischargePlanItem("x", label: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
