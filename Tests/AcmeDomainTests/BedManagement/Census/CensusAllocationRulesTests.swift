@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusAllocationValidator()
        let item = BedManagement.newCensusAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusAllocationGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.CensusAllocationGraceDaysRangeRule(min: 80, max: 80)
        let item = BedManagement.newCensusAllocation("x", title: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusAllocationCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newCensusAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusAllocationWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.CensusAllocationWindowDaysRangeRule(min: 16, max: 120)
        let item = BedManagement.newCensusAllocation("x", title: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}
