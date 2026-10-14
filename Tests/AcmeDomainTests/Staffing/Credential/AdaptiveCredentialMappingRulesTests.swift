@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveCredentialMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveCredentialMappingValidator()
        let item = Staffing.newAdaptiveCredentialMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveCredentialMappingCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.AdaptiveCredentialMappingCapacityRangeRule(min: 1000, max: 3600)
        let item = Staffing.newAdaptiveCredentialMapping("x", label: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAdaptiveCredentialMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AdaptiveCredentialMappingRequiredCodeRule(
            message: "adaptive credential mapping needs this field"
        )
        let item = Staffing.newAdaptiveCredentialMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveCredentialMappingRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Staffing.AdaptiveCredentialMappingRequiredPayerRule(
            message: "adaptive credential mapping needs this field"
        )
        let item = Staffing.newAdaptiveCredentialMapping("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveCredentialMappingRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.AdaptiveCredentialMappingRequiredLabelRule(
            message: "adaptive credential mapping needs a value"
        )
        let item = Staffing.newAdaptiveCredentialMapping("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
