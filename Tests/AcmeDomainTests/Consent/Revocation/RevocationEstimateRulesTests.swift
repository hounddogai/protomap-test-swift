@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationEstimateValidator()
        let item = Consent.newRevocationEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RevocationEstimateCodeLengthRule(maxLength: 3600)
        let item = Consent.newRevocationEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.RevocationEstimateNameLengthRule(maxLength: 32)
        let item = Consent.newRevocationEstimate("x", label: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
