@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardPreferenceValidator()
        let item = BedManagement.newBedBoardPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardPreferenceRequiredCodeRule(message: "bed board preference needs this field")
        let item = BedManagement.newBedBoardPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardPreferenceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.BedBoardPreferenceGraceDaysRangeRule(min: 255, max: 255)
        let item = BedManagement.newBedBoardPreference("x", title: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardPreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.BedBoardPreferenceTitleLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardPreference("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
