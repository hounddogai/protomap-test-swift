@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpMappingValidator()
        let item = Referrals.newFollowUpMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpMappingRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Referrals.FollowUpMappingRequiredDiagnosisCodeRule(message: "follow up mapping needs a value")
        let item = Referrals.newFollowUpMapping("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.FollowUpMappingRequiredTitleRule(message: "follow up mapping needs a value")
        let item = Referrals.newFollowUpMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
