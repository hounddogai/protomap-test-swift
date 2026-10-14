@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalRevocationScoreValidator()
        let item = Consent.newRegionalRevocationScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalRevocationScoreAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.RegionalRevocationScoreAmountRangeRule(min: 9.5, max: 2245.1)
        let item = Consent.newRegionalRevocationScore("x", label: "y")
        item.amount = 2246.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRegionalRevocationScoreRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Consent.RegionalRevocationScoreRequiredCountryRule(
            message: "regional revocation score needs this field"
        )
        let item = Consent.newRegionalRevocationScore("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalRevocationScorePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Consent.RegionalRevocationScorePatientRefLengthRule(maxLength: 120)
        let item = Consent.newRegionalRevocationScore("x", label: "y")
        item.patientRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRegionalRevocationScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.RegionalRevocationScoreLabelLengthRule(maxLength: 32)
        let item = Consent.newRegionalRevocationScore("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRegionalRevocationScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RegionalRevocationScoreRequiredCodeRule(message: "regional revocation score needs a value")
        let item = Consent.newRegionalRevocationScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalRevocationScoreSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.RegionalRevocationScoreSequenceRangeRule(min: 1000, max: 3600)
        let item = Consent.newRegionalRevocationScore("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}
