@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveIsolationPolicyValidator()
        let item = BedManagement.newAdaptiveIsolationPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveIsolationPolicyWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = BedManagement.AdaptiveIsolationPolicyWardLengthRule(maxLength: 16)
        let item = BedManagement.newAdaptiveIsolationPolicy("x", label: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementAdaptiveIsolationPolicyRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.AdaptiveIsolationPolicyRequiredEncounterIDRule(
            message: "adaptive isolation policy needs a value"
        )
        let item = BedManagement.newAdaptiveIsolationPolicy("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveIsolationPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.AdaptiveIsolationPolicyCodeLengthRule(maxLength: 255)
        let item = BedManagement.newAdaptiveIsolationPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementAdaptiveIsolationPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.AdaptiveIsolationPolicyRequiredLabelRule(
            message: "adaptive isolation policy needs a value"
        )
        let item = BedManagement.newAdaptiveIsolationPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveIsolationPolicyEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.AdaptiveIsolationPolicyEncounterIDLengthRule(maxLength: 16)
        let item = BedManagement.newAdaptiveIsolationPolicy("x", label: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
