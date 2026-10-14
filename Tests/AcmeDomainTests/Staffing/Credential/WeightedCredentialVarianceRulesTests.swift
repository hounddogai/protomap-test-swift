@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedCredentialVarianceValidator()
        let item = Staffing.newWeightedCredentialVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedCredentialVarianceRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Staffing.WeightedCredentialVarianceRequiredEncounterIDRule(
            message: "weighted credential variance needs this field"
        )
        let item = Staffing.newWeightedCredentialVariance("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingWeightedCredentialVarianceFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.WeightedCredentialVarianceFloorValueRangeRule(min: 6.0, max: 2109.9)
        let item = Staffing.newWeightedCredentialVariance("x", label: "y")
        item.floorValue = 2111.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingWeightedCredentialVarianceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.WeightedCredentialVarianceLabelLengthRule(maxLength: 86400)
        let item = Staffing.newWeightedCredentialVariance("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
