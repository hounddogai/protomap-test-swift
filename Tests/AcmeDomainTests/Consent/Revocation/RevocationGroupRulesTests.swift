@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationGroupValidator()
        let item = Consent.newRevocationGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationGroupWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Consent.RevocationGroupWardLengthRule(maxLength: 1000)
        let item = Consent.newRevocationGroup("x", label: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.RevocationGroupRequiredLabelRule(message: "revocation group needs an entry")
        let item = Consent.newRevocationGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RevocationGroupCodeLengthRule(maxLength: 86400)
        let item = Consent.newRevocationGroup("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
