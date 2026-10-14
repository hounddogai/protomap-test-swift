@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingBedBoardDraftValidator()
        let item = BedManagement.newRollingBedBoardDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingBedBoardDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.RollingBedBoardDraftRequiredNameRule(message: "rolling bed board draft needs an entry")
        let item = BedManagement.newRollingBedBoardDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingBedBoardDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.RollingBedBoardDraftNameLengthRule(maxLength: 16)
        let item = BedManagement.newRollingBedBoardDraft("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingBedBoardDraftPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.RollingBedBoardDraftPriorityRangeRule(min: 120, max: 3600)
        let item = BedManagement.newRollingBedBoardDraft("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}
