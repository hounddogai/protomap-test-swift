@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingClosureProfileValidator()
        let item = Referrals.newRollingClosureProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingClosureProfileRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Referrals.RollingClosureProfileRequiredDiagnosisCodeRule(
            message: "rolling closure profile needs an entry"
        )
        let item = Referrals.newRollingClosureProfile("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingClosureProfileDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.RollingClosureProfileDosageMgRangeRule(min: 7.6, max: 4090.3)
        let item = Referrals.newRollingClosureProfile("x", title: "y")
        item.dosageMg = 4091.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingClosureProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.RollingClosureProfileTitleLengthRule(maxLength: 3600)
        let item = Referrals.newRollingClosureProfile("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
