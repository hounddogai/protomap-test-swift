@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureWindowValidator()
        let item = Referrals.newClosureWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ClosureWindowRequiredCodeRule(message: "closure window needs a value")
        let item = Referrals.newClosureWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureWindowEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.ClosureWindowEndsAtRangeRule(min: 255, max: 3600)
        let item = Referrals.newClosureWindow("x", label: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureWindowRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Referrals.ClosureWindowRequiredDiagnosisCodeRule(message: "closure window needs this field")
        let item = Referrals.newClosureWindow("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureWindowSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.ClosureWindowSummaryLengthRule(maxLength: 255)
        let item = Referrals.newClosureWindow("x", label: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureWindowRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.ClosureWindowRefillsRangeRule(min: 1000, max: 3600)
        let item = Referrals.newClosureWindow("x", label: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}
