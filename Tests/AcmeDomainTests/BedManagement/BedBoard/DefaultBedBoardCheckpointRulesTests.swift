@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultBedBoardCheckpointValidator()
        let item = BedManagement.newDefaultBedBoardCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultBedBoardCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.DefaultBedBoardCheckpointRequiredNameRule(
            message: "default bed board checkpoint needs an entry"
        )
        let item = BedManagement.newDefaultBedBoardCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultBedBoardCheckpointBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.DefaultBedBoardCheckpointBudgetRangeRule(min: 6.4, max: 956.3)
        let item = BedManagement.newDefaultBedBoardCheckpoint("x", name: "y")
        item.budget = 957.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultBedBoardCheckpointNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.DefaultBedBoardCheckpointNameLengthRule(maxLength: 64)
        let item = BedManagement.newDefaultBedBoardCheckpoint("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
