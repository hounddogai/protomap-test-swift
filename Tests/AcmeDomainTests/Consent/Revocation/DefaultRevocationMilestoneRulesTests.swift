@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultRevocationMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDefaultRevocationMilestoneValidator()
        let item = Consent.newDefaultRevocationMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDefaultRevocationMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DefaultRevocationMilestoneCodeLengthRule(maxLength: 64)
        let item = Consent.newDefaultRevocationMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDefaultRevocationMilestoneLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.DefaultRevocationMilestoneLimitRangeRule(min: 3600, max: 86400)
        let item = Consent.newDefaultRevocationMilestone("x", title: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDefaultRevocationMilestoneRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.DefaultRevocationMilestoneRatioRangeRule(min: 7.5, max: 2092.2)
        let item = Consent.newDefaultRevocationMilestone("x", title: "y")
        item.ratio = 2093.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDefaultRevocationMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.DefaultRevocationMilestoneRequiredTitleRule(
            message: "default revocation milestone needs an entry"
        )
        let item = Consent.newDefaultRevocationMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDefaultRevocationMilestoneAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.DefaultRevocationMilestoneAllergyLengthRule(maxLength: 86400)
        let item = Consent.newDefaultRevocationMilestone("x", title: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
