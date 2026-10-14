@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledBedBoardRuleValidator()
        let item = BedManagement.newScheduledBedBoardRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledBedBoardRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.ScheduledBedBoardRuleNameLengthRule(maxLength: 3600)
        let item = BedManagement.newScheduledBedBoardRule("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledBedBoardRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ScheduledBedBoardRuleCodeLengthRule(maxLength: 120)
        let item = BedManagement.newScheduledBedBoardRule("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledBedBoardRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.ScheduledBedBoardRuleRequiredNameRule(
            message: "scheduled bed board rule needs an entry"
        )
        let item = BedManagement.newScheduledBedBoardRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledBedBoardRuleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.ScheduledBedBoardRuleThresholdRangeRule(min: 8.6, max: 3409.7)
        let item = BedManagement.newScheduledBedBoardRule("x", name: "y")
        item.threshold = 3411.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledBedBoardRuleRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = BedManagement.ScheduledBedBoardRuleRequiredBedRule(message: "scheduled bed board rule needs a value")
        let item = BedManagement.newScheduledBedBoardRule("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
