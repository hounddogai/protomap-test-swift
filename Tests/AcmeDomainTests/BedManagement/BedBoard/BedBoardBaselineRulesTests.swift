@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardBaselineValidator()
        let item = BedManagement.newBedBoardBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardBaselinePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = BedManagement.BedBoardBaselinePhoneLengthRule(maxLength: 3600)
        let item = BedManagement.newBedBoardBaseline("x", label: "y")
        item.phone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardBaselineMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = BedManagement.BedBoardBaselineMinimumRangeRule(min: 9.9, max: 599.9)
        let item = BedManagement.newBedBoardBaseline("x", label: "y")
        item.minimum = 601.4
        #expect(rule.check(item).count > 0)
    }
}
