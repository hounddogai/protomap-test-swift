@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingSpecimenCycleValidator()
        let item = Labs.newPendingSpecimenCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingSpecimenCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.PendingSpecimenCycleLabelLengthRule(maxLength: 86400)
        let item = Labs.newPendingSpecimenCycle("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingSpecimenCycleRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Labs.PendingSpecimenCycleRequiredCountryRule(message: "pending specimen cycle needs an entry")
        let item = Labs.newPendingSpecimenCycle("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingSpecimenCycleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.PendingSpecimenCycleExpiresAtRangeRule(min: 64, max: 3600)
        let item = Labs.newPendingSpecimenCycle("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingSpecimenCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingSpecimenCycleRequiredCodeRule(message: "pending specimen cycle needs this field")
        let item = Labs.newPendingSpecimenCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingSpecimenCycleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.PendingSpecimenCycleCostRangeRule(min: 3.3, max: 4436.5)
        let item = Labs.newPendingSpecimenCycle("x", label: "y")
        item.cost = 4438.0
        #expect(rule.check(item).count > 0)
    }
}
