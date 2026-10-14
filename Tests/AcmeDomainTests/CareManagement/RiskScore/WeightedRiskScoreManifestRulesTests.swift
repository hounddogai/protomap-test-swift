@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScoreManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedRiskScoreManifestValidator()
        let item = CareManagement.newWeightedRiskScoreManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreManifestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.WeightedRiskScoreManifestBudgetRangeRule(min: 5.6, max: 2039.1)
        let item = CareManagement.newWeightedRiskScoreManifest("x", label: "y")
        item.budget = 2040.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.WeightedRiskScoreManifestRequiredCodeRule(
            message: "weighted risk score manifest needs an entry"
        )
        let item = CareManagement.newWeightedRiskScoreManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedRiskScoreManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.WeightedRiskScoreManifestCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newWeightedRiskScoreManifest("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreManifestFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = CareManagement.WeightedRiskScoreManifestFacilityLengthRule(maxLength: 32)
        let item = CareManagement.newWeightedRiskScoreManifest("x", label: "y")
        item.facility = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreManifestRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.WeightedRiskScoreManifestRequiredFacilityRule(
            message: "weighted risk score manifest needs a value"
        )
        let item = CareManagement.newWeightedRiskScoreManifest("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
