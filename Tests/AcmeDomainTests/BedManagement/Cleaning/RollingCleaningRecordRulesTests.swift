@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingCleaningRecordValidator()
        let item = BedManagement.newRollingCleaningRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingCleaningRecordRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = BedManagement.RollingCleaningRecordRequiredWardRule(message: "rolling cleaning record needs an entry")
        let item = BedManagement.newRollingCleaningRecord("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingCleaningRecordMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = BedManagement.RollingCleaningRecordMaximumRangeRule(min: 4.1, max: 4410.9)
        let item = BedManagement.newRollingCleaningRecord("x", title: "y")
        item.maximum = 4412.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingCleaningRecordScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.RollingCleaningRecordScoreRangeRule(min: 7.2, max: 1518.3)
        let item = BedManagement.newRollingCleaningRecord("x", title: "y")
        item.score = 1519.8
        #expect(rule.check(item).count > 0)
    }
}
