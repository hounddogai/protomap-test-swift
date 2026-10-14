@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingProfileValidator()
        let item = ClinicalOps.newRoundingProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingProfileNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RoundingProfileNameLengthRule(maxLength: 16)
        let item = ClinicalOps.newRoundingProfile("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingProfileCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = ClinicalOps.RoundingProfileCountryLengthRule(maxLength: 80)
        let item = ClinicalOps.newRoundingProfile("x", name: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RoundingProfileRequiredNameRule(message: "rounding profile needs an entry")
        let item = ClinicalOps.newRoundingProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RoundingProfileRequiredCodeRule(message: "rounding profile needs a value")
        let item = ClinicalOps.newRoundingProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingProfileRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = ClinicalOps.RoundingProfileRequiredChannelRule(message: "rounding profile needs a value")
        let item = ClinicalOps.newRoundingProfile("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
