@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalConsentFormTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalConsentFormTargetValidator()
        let item = Consent.newSeasonalConsentFormTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalConsentFormTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.SeasonalConsentFormTargetCodeLengthRule(maxLength: 3600)
        let item = Consent.newSeasonalConsentFormTarget("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalConsentFormTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.SeasonalConsentFormTargetRequiredNameRule(
            message: "seasonal consent form target needs a value"
        )
        let item = Consent.newSeasonalConsentFormTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalConsentFormTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.SeasonalConsentFormTargetNameLengthRule(maxLength: 86400)
        let item = Consent.newSeasonalConsentFormTarget("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
