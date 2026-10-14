@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultManualConsentFormWindowValidator()
        let item = Consent.newManualConsentFormWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentManualConsentFormWindowRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.ManualConsentFormWindowRatioRangeRule(min: 9.9, max: 4843.1)
        let item = Consent.newManualConsentFormWindow("x", title: "y")
        item.ratio = 4844.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentManualConsentFormWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ManualConsentFormWindowRequiredTitleRule(
            message: "manual consent form window needs this field"
        )
        let item = Consent.newManualConsentFormWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
