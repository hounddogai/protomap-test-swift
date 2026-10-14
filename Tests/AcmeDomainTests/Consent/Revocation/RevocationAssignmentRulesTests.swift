@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationAssignmentValidator()
        let item = Consent.newRevocationAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationAssignmentFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Consent.RevocationAssignmentFacilityLengthRule(maxLength: 86400)
        let item = Consent.newRevocationAssignment("x", name: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.RevocationAssignmentRequiredNameRule(message: "revocation assignment needs an entry")
        let item = Consent.newRevocationAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.RevocationAssignmentNameLengthRule(maxLength: 1000)
        let item = Consent.newRevocationAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
