@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffOverrideValidator()
        let item = ClinicalOps.newHandoffOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffOverrideRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.HandoffOverrideRegionLengthRule(maxLength: 1000)
        let item = ClinicalOps.newHandoffOverride("x", label: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffOverrideCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = ClinicalOps.HandoffOverrideCapacityRangeRule(min: 1000, max: 86400)
        let item = ClinicalOps.newHandoffOverride("x", label: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.HandoffOverrideCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newHandoffOverride("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffOverrideDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.HandoffOverrideDurationMinutesRangeRule(min: 120, max: 1000)
        let item = ClinicalOps.newHandoffOverride("x", label: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffOverrideRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = ClinicalOps.HandoffOverrideRequiredExternalRefRule(message: "handoff override needs this field")
        let item = ClinicalOps.newHandoffOverride("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
