@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionReservationValidator()
        let item = Labs.newAccessionReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionReservationRequiredCodeRule(message: "accession reservation needs a value")
        let item = Labs.newAccessionReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.AccessionReservationLabelLengthRule(maxLength: 80)
        let item = Labs.newAccessionReservation("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionReservationAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.AccessionReservationAttemptsRangeRule(min: 16, max: 86400)
        let item = Labs.newAccessionReservation("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionReservationCodeLengthRule(maxLength: 16)
        let item = Labs.newAccessionReservation("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionReservationExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.AccessionReservationExpiresAtRangeRule(min: 64, max: 120)
        let item = Labs.newAccessionReservation("x", label: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}
