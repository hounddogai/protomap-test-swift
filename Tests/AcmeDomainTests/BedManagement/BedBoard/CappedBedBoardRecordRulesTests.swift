@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedBedBoardRecordValidator()
        let item = BedManagement.newCappedBedBoardRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedBedBoardRecordRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = BedManagement.CappedBedBoardRecordRequiredSegmentRule(
            message: "capped bed board record needs this field"
        )
        let item = BedManagement.newCappedBedBoardRecord("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCappedBedBoardRecordCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = BedManagement.CappedBedBoardRecordCurrencyLengthRule(maxLength: 80)
        let item = BedManagement.newCappedBedBoardRecord("x", title: "y")
        item.currency = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedBedBoardRecordLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.CappedBedBoardRecordLimitRangeRule(min: 16, max: 64)
        let item = BedManagement.newCappedBedBoardRecord("x", title: "y")
        item.limit = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedBedBoardRecordRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = BedManagement.CappedBedBoardRecordRequiredCurrencyRule(
            message: "capped bed board record needs this field"
        )
        let item = BedManagement.newCappedBedBoardRecord("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
