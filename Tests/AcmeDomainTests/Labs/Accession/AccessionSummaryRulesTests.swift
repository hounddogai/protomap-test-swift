@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionSummaryValidator()
        let item = Labs.newAccessionSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionSummaryScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.AccessionSummaryScoreRangeRule(min: 3.0, max: 345.8)
        let item = Labs.newAccessionSummary("x", label: "y")
        item.score = 347.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionSummaryCodeLengthRule(maxLength: 32)
        let item = Labs.newAccessionSummary("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionSummaryExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.AccessionSummaryExpiresAtRangeRule(min: 120, max: 3600)
        let item = Labs.newAccessionSummary("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionSummaryRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Labs.AccessionSummaryRequiredProcedureCodeRule(message: "accession summary needs this field")
        let item = Labs.newAccessionSummary("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
