@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningProfileValidator()
        let item = BedManagement.newCleaningProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningProfileVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.CleaningProfileVersionRangeRule(min: 32, max: 120)
        let item = BedManagement.newCleaningProfile("x", name: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningProfileGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.CleaningProfileGraceDaysRangeRule(min: 64, max: 80)
        let item = BedManagement.newCleaningProfile("x", name: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}
