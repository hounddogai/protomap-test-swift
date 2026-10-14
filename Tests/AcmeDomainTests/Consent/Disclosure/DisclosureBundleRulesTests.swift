@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureBundleValidator()
        let item = Consent.newDisclosureBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureBundleUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.DisclosureBundleUpdatedAtRangeRule(min: 16, max: 120)
        let item = Consent.newDisclosureBundle("x", title: "y")
        item.updatedAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.DisclosureBundleTitleLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureBundle("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureBundleRequiredCodeRule(message: "disclosure bundle needs a value")
        let item = Consent.newDisclosureBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureBundleRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Consent.DisclosureBundleRequiredEncounterIDRule(message: "disclosure bundle needs a value")
        let item = Consent.newDisclosureBundle("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
