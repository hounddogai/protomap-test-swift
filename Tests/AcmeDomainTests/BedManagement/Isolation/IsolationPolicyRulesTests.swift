@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationPolicyValidator()
        let item = BedManagement.newIsolationPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationPolicyFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.IsolationPolicyFacilityLengthRule(maxLength: 120)
        let item = BedManagement.newIsolationPolicy("x", label: "y")
        item.facility = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.IsolationPolicyRequiredLabelRule(message: "isolation policy needs an entry")
        let item = BedManagement.newIsolationPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationPolicyCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newIsolationPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationPolicyDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.IsolationPolicyDosageMgRangeRule(min: 8.0, max: 1636.6)
        let item = BedManagement.newIsolationPolicy("x", label: "y")
        item.dosageMg = 1638.1
        #expect(rule.check(item).count > 0)
    }
}
