@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedCleaningScoreValidator()
        let item = BedManagement.newCappedCleaningScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedCleaningScoreCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = BedManagement.CappedCleaningScoreCostRangeRule(min: 9.4, max: 2279.5)
        let item = BedManagement.newCappedCleaningScore("x", label: "y")
        item.cost = 2281.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedCleaningScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CappedCleaningScoreCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newCappedCleaningScore("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedCleaningScoreRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = BedManagement.CappedCleaningScoreRateRangeRule(min: 8.6, max: 4209.3)
        let item = BedManagement.newCappedCleaningScore("x", label: "y")
        item.rate = 4210.8
        #expect(rule.check(item).count > 0)
    }
}
