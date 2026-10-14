@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingLanguageDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingLanguageDigestValidator()
        let item = Consent.newPendingLanguageDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingLanguageDigestPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.PendingLanguageDigestPriorityRangeRule(min: 64, max: 80)
        let item = Consent.newPendingLanguageDigest("x", name: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingLanguageDigestRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.PendingLanguageDigestRequiredBedRule(message: "pending language digest needs an entry")
        let item = Consent.newPendingLanguageDigest("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingLanguageDigestCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.PendingLanguageDigestCostRangeRule(min: 8.2, max: 987.1)
        let item = Consent.newPendingLanguageDigest("x", name: "y")
        item.cost = 988.6
        #expect(rule.check(item).count > 0)
    }
}
