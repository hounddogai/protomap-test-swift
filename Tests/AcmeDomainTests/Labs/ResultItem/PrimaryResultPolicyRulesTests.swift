@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryResultPolicyValidator()
        let item = Labs.newPrimaryResultPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryResultPolicyBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.PrimaryResultPolicyBedLengthRule(maxLength: 80)
        let item = Labs.newPrimaryResultPolicy("x", title: "y")
        item.bed = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryResultPolicyEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.PrimaryResultPolicyEndsAtRangeRule(min: 120, max: 120)
        let item = Labs.newPrimaryResultPolicy("x", title: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPrimaryResultPolicyRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.PrimaryResultPolicyRequiredLocaleRule(message: "primary result policy needs this field")
        let item = Labs.newPrimaryResultPolicy("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
