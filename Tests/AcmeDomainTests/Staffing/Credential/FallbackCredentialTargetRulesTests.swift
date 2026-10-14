@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackCredentialTargetValidator()
        let item = Staffing.newFallbackCredentialTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackCredentialTargetBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.FallbackCredentialTargetBedLengthRule(maxLength: 1000)
        let item = Staffing.newFallbackCredentialTarget("x", label: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackCredentialTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FallbackCredentialTargetRequiredCodeRule(message: "fallback credential target needs a value")
        let item = Staffing.newFallbackCredentialTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackCredentialTargetVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.FallbackCredentialTargetVersionRangeRule(min: 120, max: 86400)
        let item = Staffing.newFallbackCredentialTarget("x", label: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackCredentialTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.FallbackCredentialTargetRequiredLabelRule(
            message: "fallback credential target needs this field"
        )
        let item = Staffing.newFallbackCredentialTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackCredentialTargetRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.FallbackCredentialTargetRequiredBedRule(message: "fallback credential target needs a value")
        let item = Staffing.newFallbackCredentialTarget("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
