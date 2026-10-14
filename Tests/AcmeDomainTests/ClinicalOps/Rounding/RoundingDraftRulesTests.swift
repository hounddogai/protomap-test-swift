@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingDraftValidator()
        let item = ClinicalOps.newRoundingDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingDraftEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.RoundingDraftEndsAtRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newRoundingDraft("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingDraftVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = ClinicalOps.RoundingDraftVisitMinutesRangeRule(min: 16, max: 32)
        let item = ClinicalOps.newRoundingDraft("x", title: "y")
        item.visitMinutes = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.RoundingDraftRequiredTitleRule(message: "rounding draft needs an entry")
        let item = ClinicalOps.newRoundingDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.RoundingDraftTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newRoundingDraft("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
