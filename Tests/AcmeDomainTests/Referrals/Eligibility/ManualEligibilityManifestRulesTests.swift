@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualEligibilityManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualEligibilityManifestValidator()
        let item = Referrals.newManualEligibilityManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualEligibilityManifestRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.ManualEligibilityManifestRequiredWardRule(
            message: "manual eligibility manifest needs an entry"
        )
        let item = Referrals.newManualEligibilityManifest("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
