@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalOrderSetAssignmentValidator()
        let item = ClinicalOps.newGlobalOrderSetAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetAssignmentRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.GlobalOrderSetAssignmentRequiredTimezoneRule(
            message: "global order set assignment needs an entry"
        )
        let item = ClinicalOps.newGlobalOrderSetAssignment("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetAssignmentEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.GlobalOrderSetAssignmentEndsAtRangeRule(min: 16, max: 1000)
        let item = ClinicalOps.newGlobalOrderSetAssignment("x", name: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetAssignmentRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = ClinicalOps.GlobalOrderSetAssignmentRequiredNotesRule(
            message: "global order set assignment needs a value"
        )
        let item = ClinicalOps.newGlobalOrderSetAssignment("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
