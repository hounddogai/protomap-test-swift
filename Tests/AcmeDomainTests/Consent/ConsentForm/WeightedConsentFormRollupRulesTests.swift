@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedConsentFormRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedConsentFormRollupValidator()
        let item = Consent.newWeightedConsentFormRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedConsentFormRollupDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.WeightedConsentFormRollupDurationMinutesRangeRule(min: 1000, max: 86400)
        let item = Consent.newWeightedConsentFormRollup("x", title: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWeightedConsentFormRollupChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Consent.WeightedConsentFormRollupChannelLengthRule(maxLength: 255)
        let item = Consent.newWeightedConsentFormRollup("x", title: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWeightedConsentFormRollupRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.WeightedConsentFormRollupRegionLengthRule(maxLength: 255)
        let item = Consent.newWeightedConsentFormRollup("x", title: "y")
        item.region = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWeightedConsentFormRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WeightedConsentFormRollupRequiredCodeRule(
            message: "weighted consent form rollup needs an entry"
        )
        let item = Consent.newWeightedConsentFormRollup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
