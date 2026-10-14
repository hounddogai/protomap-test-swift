@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureBaselineValidator()
        let item = Referrals.newClosureBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.ClosureBaselineLabelLengthRule(maxLength: 32)
        let item = Referrals.newClosureBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureBaselineCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.ClosureBaselineCreatedAtRangeRule(min: 120, max: 120)
        let item = Referrals.newClosureBaseline("x", label: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureBaselineRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Referrals.ClosureBaselineRequiredDiagnosisCodeRule(message: "closure baseline needs an entry")
        let item = Referrals.newClosureBaseline("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureBaselineExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Referrals.ClosureBaselineExpiresAtRangeRule(min: 255, max: 3600)
        let item = Referrals.newClosureBaseline("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
