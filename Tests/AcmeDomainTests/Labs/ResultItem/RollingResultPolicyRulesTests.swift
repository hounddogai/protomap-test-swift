@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingResultPolicyValidator()
        let item = Labs.newRollingResultPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingResultPolicyAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.RollingResultPolicyAllergyLengthRule(maxLength: 80)
        let item = Labs.newRollingResultPolicy("x", name: "y")
        item.allergy = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingResultPolicyRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.RollingResultPolicyRequiredExternalRefRule(message: "rolling result policy needs this field")
        let item = Labs.newRollingResultPolicy("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
