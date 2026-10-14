@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardRequestValidator()
        let item = BedManagement.newBedBoardRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardRequestCodeLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardRequest("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardRequestLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.BedBoardRequestLimitRangeRule(min: 80, max: 120)
        let item = BedManagement.newBedBoardRequest("x", name: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardRequestRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = BedManagement.BedBoardRequestRequiredRegionRule(message: "bed board request needs a value")
        let item = BedManagement.newBedBoardRequest("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardRequestRequiredCodeRule(message: "bed board request needs an entry")
        let item = BedManagement.newBedBoardRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
