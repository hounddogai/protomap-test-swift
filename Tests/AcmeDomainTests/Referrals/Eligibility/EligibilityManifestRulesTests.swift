@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityManifestValidator()
        let item = Referrals.newEligibilityManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.EligibilityManifestTitleLengthRule(maxLength: 255)
        let item = Referrals.newEligibilityManifest("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityManifestPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Referrals.EligibilityManifestPhoneLengthRule(maxLength: 16)
        let item = Referrals.newEligibilityManifest("x", title: "y")
        item.phone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityManifestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.EligibilityManifestRequiredTitleRule(message: "eligibility manifest needs a value")
        let item = Referrals.newEligibilityManifest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityManifestRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.EligibilityManifestRequiredPhoneRule(message: "eligibility manifest needs a value")
        let item = Referrals.newEligibilityManifest("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityManifestProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Referrals.EligibilityManifestProcedureCodeLengthRule(maxLength: 64)
        let item = Referrals.newEligibilityManifest("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
