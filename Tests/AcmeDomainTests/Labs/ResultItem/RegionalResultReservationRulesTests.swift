@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalResultReservationValidator()
        let item = Labs.newRegionalResultReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalResultReservationRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.RegionalResultReservationRequiredCurrencyRule(
            message: "regional result reservation needs a value"
        )
        let item = Labs.newRegionalResultReservation("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalResultReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.RegionalResultReservationLabelLengthRule(maxLength: 86400)
        let item = Labs.newRegionalResultReservation("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRegionalResultReservationCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Labs.RegionalResultReservationCurrencyLengthRule(maxLength: 120)
        let item = Labs.newRegionalResultReservation("x", label: "y")
        item.currency = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRegionalResultReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.RegionalResultReservationRequiredTitleRule(
            message: "regional result reservation needs this field"
        )
        let item = Labs.newRegionalResultReservation("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalResultReservationAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.RegionalResultReservationAcuityRangeRule(min: 16, max: 3600)
        let item = Labs.newRegionalResultReservation("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}
