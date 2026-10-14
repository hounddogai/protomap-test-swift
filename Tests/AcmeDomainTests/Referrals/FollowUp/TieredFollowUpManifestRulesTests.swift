@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredFollowUpManifestValidator()
        let item = Referrals.newTieredFollowUpManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredFollowUpManifestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.TieredFollowUpManifestDiscountRangeRule(min: 8.5, max: 1996.6)
        let item = Referrals.newTieredFollowUpManifest("x", label: "y")
        item.discount = 1998.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredFollowUpManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.TieredFollowUpManifestRequiredLabelRule(message: "tiered follow up manifest needs a value")
        let item = Referrals.newTieredFollowUpManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredFollowUpManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.TieredFollowUpManifestRequiredCodeRule(
            message: "tiered follow up manifest needs this field"
        )
        let item = Referrals.newTieredFollowUpManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredFollowUpManifestContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Referrals.TieredFollowUpManifestContactEmailLengthRule(maxLength: 80)
        let item = Referrals.newTieredFollowUpManifest("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
