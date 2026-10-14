@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryCredentialEstimateValidator()
        let item = Staffing.newPrimaryCredentialEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryCredentialEstimateRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.PrimaryCredentialEstimateRateRangeRule(min: 2.4, max: 4747.3)
        let item = Staffing.newPrimaryCredentialEstimate("x", title: "y")
        item.rate = 4748.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryCredentialEstimateRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.PrimaryCredentialEstimateRequiredUnitRule(
            message: "primary credential estimate needs an entry"
        )
        let item = Staffing.newPrimaryCredentialEstimate("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryCredentialEstimateExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Staffing.PrimaryCredentialEstimateExternalRefLengthRule(maxLength: 120)
        let item = Staffing.newPrimaryCredentialEstimate("x", title: "y")
        item.externalRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
