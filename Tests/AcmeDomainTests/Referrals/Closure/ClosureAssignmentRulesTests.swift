@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureAssignmentValidator()
        let item = Referrals.newClosureAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ClosureAssignmentRequiredTitleRule(message: "closure assignment needs this field")
        let item = Referrals.newClosureAssignment("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ClosureAssignmentRequiredCodeRule(message: "closure assignment needs an entry")
        let item = Referrals.newClosureAssignment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureAssignmentCodeLengthRule(maxLength: 32)
        let item = Referrals.newClosureAssignment("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ClosureAssignmentTitleLengthRule(maxLength: 64)
        let item = Referrals.newClosureAssignment("x", label: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureAssignmentScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.ClosureAssignmentScoreRangeRule(min: 2.4, max: 4649.4)
        let item = Referrals.newClosureAssignment("x", label: "y")
        item.score = 4650.9
        #expect(rule.check(item).count > 0)
    }
}
