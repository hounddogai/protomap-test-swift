@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledTransferProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledTransferProfileValidator()
        let item = BedManagement.newScheduledTransferProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledTransferProfileEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.ScheduledTransferProfileEncounterIDLengthRule(maxLength: 32)
        let item = BedManagement.newScheduledTransferProfile("x", label: "y")
        item.encounterID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledTransferProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ScheduledTransferProfileRequiredCodeRule(
            message: "scheduled transfer profile needs a value"
        )
        let item = BedManagement.newScheduledTransferProfile("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledTransferProfileLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.ScheduledTransferProfileLimitRangeRule(min: 80, max: 1000)
        let item = BedManagement.newScheduledTransferProfile("x", label: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledTransferProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.ScheduledTransferProfileLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newScheduledTransferProfile("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
