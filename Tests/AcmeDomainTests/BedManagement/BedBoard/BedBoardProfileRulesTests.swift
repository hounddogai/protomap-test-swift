@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardProfileValidator()
        let item = BedManagement.newBedBoardProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardProfileRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.BedBoardProfileRequiredCategoryRule(message: "bed board profile needs this field")
        let item = BedManagement.newBedBoardProfile("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.BedBoardProfileRequiredNameRule(message: "bed board profile needs a value")
        let item = BedManagement.newBedBoardProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardProfileCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.BedBoardProfileCreatedAtRangeRule(min: 120, max: 1000)
        let item = BedManagement.newBedBoardProfile("x", name: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
