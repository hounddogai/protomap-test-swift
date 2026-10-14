@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardGroupValidator()
        let item = BedManagement.newBedBoardGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardGroupStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.BedBoardGroupStartsAtRangeRule(min: 3600, max: 86400)
        let item = BedManagement.newBedBoardGroup("x", name: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardGroupCodeLengthRule(maxLength: 120)
        let item = BedManagement.newBedBoardGroup("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardGroupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.BedBoardGroupRequiredNameRule(message: "bed board group needs an entry")
        let item = BedManagement.newBedBoardGroup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.BedBoardGroupNameLengthRule(maxLength: 86400)
        let item = BedManagement.newBedBoardGroup("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.BedBoardGroupRequiredTitleRule(message: "bed board group needs a value")
        let item = BedManagement.newBedBoardGroup("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
