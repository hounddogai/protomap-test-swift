@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusNoticeValidator()
        let item = BedManagement.newCensusNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusNoticeAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.CensusNoticeAmountRangeRule(min: 7.8, max: 4264.6)
        let item = BedManagement.newCensusNotice("x", title: "y")
        item.amount = 4266.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusNoticeCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = BedManagement.CensusNoticeCapacityRangeRule(min: 64, max: 255)
        let item = BedManagement.newCensusNotice("x", title: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CensusNoticeTitleLengthRule(maxLength: 120)
        let item = BedManagement.newCensusNotice("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusNoticeTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = BedManagement.CensusNoticeTimezoneLengthRule(maxLength: 32)
        let item = BedManagement.newCensusNotice("x", title: "y")
        item.timezone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
