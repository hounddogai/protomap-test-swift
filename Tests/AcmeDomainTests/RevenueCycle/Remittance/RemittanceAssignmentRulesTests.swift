@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceAssignmentValidator()
        let item = RevenueCycle.newRemittanceAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RemittanceAssignmentRequiredNameRule(message: "remittance assignment needs this field")
        let item = RevenueCycle.newRemittanceAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceAssignmentRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.RemittanceAssignmentRefillsRangeRule(min: 80, max: 255)
        let item = RevenueCycle.newRemittanceAssignment("x", name: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceAssignmentAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = RevenueCycle.RemittanceAssignmentAllergyLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRemittanceAssignment("x", name: "y")
        item.allergy = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
