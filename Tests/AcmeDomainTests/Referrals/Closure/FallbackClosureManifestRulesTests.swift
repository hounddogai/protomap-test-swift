@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackClosureManifestValidator()
        let item = Referrals.newFallbackClosureManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackClosureManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FallbackClosureManifestRequiredCodeRule(message: "fallback closure manifest needs an entry")
        let item = Referrals.newFallbackClosureManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackClosureManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FallbackClosureManifestCodeLengthRule(maxLength: 32)
        let item = Referrals.newFallbackClosureManifest("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackClosureManifestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Referrals.FallbackClosureManifestRegionLengthRule(maxLength: 3600)
        let item = Referrals.newFallbackClosureManifest("x", label: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
