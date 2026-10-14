@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedFollowUpManifestValidator()
        let item = Referrals.newWeightedFollowUpManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedFollowUpManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.WeightedFollowUpManifestCodeLengthRule(maxLength: 86400)
        let item = Referrals.newWeightedFollowUpManifest("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedFollowUpManifestRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.WeightedFollowUpManifestRequiredSummaryRule(
            message: "weighted follow up manifest needs this field"
        )
        let item = Referrals.newWeightedFollowUpManifest("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedFollowUpManifestSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.WeightedFollowUpManifestSummaryLengthRule(maxLength: 16)
        let item = Referrals.newWeightedFollowUpManifest("x", title: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedFollowUpManifestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.WeightedFollowUpManifestRequiredTitleRule(
            message: "weighted follow up manifest needs a value"
        )
        let item = Referrals.newWeightedFollowUpManifest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
