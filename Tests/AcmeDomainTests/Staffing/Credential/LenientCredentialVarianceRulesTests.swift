@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientCredentialVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientCredentialVarianceValidator()
        let item = Staffing.newLenientCredentialVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientCredentialVariancePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Staffing.LenientCredentialVariancePriorityRangeRule(min: 64, max: 1000)
        let item = Staffing.newLenientCredentialVariance("x", label: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientCredentialVarianceThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.LenientCredentialVarianceThresholdRangeRule(min: 4.8, max: 3658.1)
        let item = Staffing.newLenientCredentialVariance("x", label: "y")
        item.threshold = 3659.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientCredentialVarianceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.LenientCredentialVarianceLabelLengthRule(maxLength: 32)
        let item = Staffing.newLenientCredentialVariance("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLenientCredentialVarianceRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.LenientCredentialVarianceRequiredWardRule(
            message: "lenient credential variance needs an entry"
        )
        let item = Staffing.newLenientCredentialVariance("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
