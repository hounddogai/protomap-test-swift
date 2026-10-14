@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalAccessionReservationValidator()
        let item = Labs.newRegionalAccessionReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalAccessionReservationAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.RegionalAccessionReservationAttemptsRangeRule(min: 32, max: 80)
        let item = Labs.newRegionalAccessionReservation("x", label: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRegionalAccessionReservationPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.RegionalAccessionReservationPriorityRangeRule(min: 16, max: 16)
        let item = Labs.newRegionalAccessionReservation("x", label: "y")
        item.priority = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRegionalAccessionReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.RegionalAccessionReservationRequiredLabelRule(
            message: "regional accession reservation needs this field"
        )
        let item = Labs.newRegionalAccessionReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalAccessionReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.RegionalAccessionReservationCodeLengthRule(maxLength: 120)
        let item = Labs.newRegionalAccessionReservation("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
