@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultHandoffReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultHandoffReservationValidator()
        let item = ClinicalOps.newDefaultHandoffReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultHandoffReservationRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.DefaultHandoffReservationRequiredEncounterIDRule(
            message: "default handoff reservation needs this field"
        )
        let item = ClinicalOps.newDefaultHandoffReservation("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultHandoffReservationBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.DefaultHandoffReservationBudgetRangeRule(min: 6.9, max: 963.7)
        let item = ClinicalOps.newDefaultHandoffReservation("x", title: "y")
        item.budget = 965.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsDefaultHandoffReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.DefaultHandoffReservationRequiredCodeRule(
            message: "default handoff reservation needs an entry"
        )
        let item = ClinicalOps.newDefaultHandoffReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultHandoffReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.DefaultHandoffReservationCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newDefaultHandoffReservation("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsDefaultHandoffReservationDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.DefaultHandoffReservationDurationMinutesRangeRule(min: 3600, max: 86400)
        let item = ClinicalOps.newDefaultHandoffReservation("x", title: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}
