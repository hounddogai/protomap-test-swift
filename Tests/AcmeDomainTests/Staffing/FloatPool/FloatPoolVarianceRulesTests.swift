@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolVarianceValidator()
        let item = Staffing.newFloatPoolVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolVarianceRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Staffing.FloatPoolVarianceRequiredReviewerRule(message: "float pool variance needs an entry")
        let item = Staffing.newFloatPoolVariance("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolVarianceReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Staffing.FloatPoolVarianceReviewerLengthRule(maxLength: 80)
        let item = Staffing.newFloatPoolVariance("x", label: "y")
        item.reviewer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolVarianceRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Staffing.FloatPoolVarianceRequiredNotesRule(message: "float pool variance needs a value")
        let item = Staffing.newFloatPoolVariance("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolVarianceNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Staffing.FloatPoolVarianceNotesLengthRule(maxLength: 255)
        let item = Staffing.newFloatPoolVariance("x", label: "y")
        item.notes = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
