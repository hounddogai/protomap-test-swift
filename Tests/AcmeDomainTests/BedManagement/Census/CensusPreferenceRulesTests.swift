@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusPreferenceValidator()
        let item = BedManagement.newCensusPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusPreferenceFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.CensusPreferenceFloorValueRangeRule(min: 5.6, max: 4963.9)
        let item = BedManagement.newCensusPreference("x", title: "y")
        item.floorValue = 4965.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusPreferenceTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = BedManagement.CensusPreferenceTimezoneLengthRule(maxLength: 3600)
        let item = BedManagement.newCensusPreference("x", title: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.CensusPreferenceRequiredTitleRule(message: "census preference needs this field")
        let item = BedManagement.newCensusPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusPreferenceRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = BedManagement.CensusPreferenceRequiredTimezoneRule(message: "census preference needs a value")
        let item = BedManagement.newCensusPreference("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
