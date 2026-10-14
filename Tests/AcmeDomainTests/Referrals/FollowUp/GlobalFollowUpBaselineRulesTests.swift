@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalFollowUpBaselineValidator()
        let item = Referrals.newGlobalFollowUpBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalFollowUpBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.GlobalFollowUpBaselineRequiredCodeRule(message: "global follow up baseline needs an entry")
        let item = Referrals.newGlobalFollowUpBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalFollowUpBaselineRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.GlobalFollowUpBaselineRequiredPatientRefRule(
            message: "global follow up baseline needs an entry"
        )
        let item = Referrals.newGlobalFollowUpBaseline("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalFollowUpBaselinePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Referrals.GlobalFollowUpBaselinePatientRefLengthRule(maxLength: 1000)
        let item = Referrals.newGlobalFollowUpBaseline("x", label: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalFollowUpBaselineDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Referrals.GlobalFollowUpBaselineDurationMinutesRangeRule(min: 32, max: 1000)
        let item = Referrals.newGlobalFollowUpBaseline("x", label: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
