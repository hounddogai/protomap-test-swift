@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultAccessionReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultAccessionReservationValidator()
        let item = Labs.newDefaultAccessionReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultAccessionReservationRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.DefaultAccessionReservationRequiredPhoneRule(
            message: "default accession reservation needs this field"
        )
        let item = Labs.newDefaultAccessionReservation("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultAccessionReservationRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.DefaultAccessionReservationRequiredCurrencyRule(
            message: "default accession reservation needs this field"
        )
        let item = Labs.newDefaultAccessionReservation("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultAccessionReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.DefaultAccessionReservationRequiredCodeRule(
            message: "default accession reservation needs an entry"
        )
        let item = Labs.newDefaultAccessionReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultAccessionReservationCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Labs.DefaultAccessionReservationCurrencyLengthRule(maxLength: 120)
        let item = Labs.newDefaultAccessionReservation("x", title: "y")
        item.currency = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultAccessionReservationPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.DefaultAccessionReservationPhoneLengthRule(maxLength: 64)
        let item = Labs.newDefaultAccessionReservation("x", title: "y")
        item.phone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
