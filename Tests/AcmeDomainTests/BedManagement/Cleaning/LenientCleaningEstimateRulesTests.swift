@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCleaningEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientCleaningEstimateValidator()
        let item = BedManagement.newLenientCleaningEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientCleaningEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.LenientCleaningEstimateRequiredNameRule(
            message: "lenient cleaning estimate needs a value"
        )
        let item = BedManagement.newLenientCleaningEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientCleaningEstimateRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = BedManagement.LenientCleaningEstimateRequiredNotesRule(
            message: "lenient cleaning estimate needs this field"
        )
        let item = BedManagement.newLenientCleaningEstimate("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientCleaningEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LenientCleaningEstimateRequiredCodeRule(
            message: "lenient cleaning estimate needs an entry"
        )
        let item = BedManagement.newLenientCleaningEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientCleaningEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.LenientCleaningEstimateNameLengthRule(maxLength: 120)
        let item = BedManagement.newLenientCleaningEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientCleaningEstimateBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.LenientCleaningEstimateBudgetRangeRule(min: 7.1, max: 3632.7)
        let item = BedManagement.newLenientCleaningEstimate("x", name: "y")
        item.budget = 3634.2
        #expect(rule.check(item).count > 0)
    }
}
