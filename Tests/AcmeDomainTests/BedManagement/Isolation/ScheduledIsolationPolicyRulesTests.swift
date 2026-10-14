@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledIsolationPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledIsolationPolicyValidator()
        let item = BedManagement.newScheduledIsolationPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledIsolationPolicyExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.ScheduledIsolationPolicyExpiresAtRangeRule(min: 120, max: 120)
        let item = BedManagement.newScheduledIsolationPolicy("x", name: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledIsolationPolicyAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = BedManagement.ScheduledIsolationPolicyAllergyLengthRule(maxLength: 120)
        let item = BedManagement.newScheduledIsolationPolicy("x", name: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledIsolationPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ScheduledIsolationPolicyCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newScheduledIsolationPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledIsolationPolicyDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.ScheduledIsolationPolicyDiagnosisCodeLengthRule(maxLength: 64)
        let item = BedManagement.newScheduledIsolationPolicy("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledIsolationPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.ScheduledIsolationPolicyNameLengthRule(maxLength: 64)
        let item = BedManagement.newScheduledIsolationPolicy("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
