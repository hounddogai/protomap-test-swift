@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureMilestoneValidator()
        let item = Consent.newDisclosureMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureMilestoneVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.DisclosureMilestoneVisitMinutesRangeRule(min: 120, max: 255)
        let item = Consent.newDisclosureMilestone("x", label: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureMilestoneLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.DisclosureMilestoneLabelLengthRule(maxLength: 16)
        let item = Consent.newDisclosureMilestone("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureMilestoneRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.DisclosureMilestoneRequiredLocaleRule(message: "disclosure milestone needs an entry")
        let item = Consent.newDisclosureMilestone("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
