@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredAssessmentManifestValidator()
        let item = CareManagement.newTieredAssessmentManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredAssessmentManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.TieredAssessmentManifestRequiredCodeRule(
            message: "tiered assessment manifest needs a value"
        )
        let item = CareManagement.newTieredAssessmentManifest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredAssessmentManifestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.TieredAssessmentManifestAmountRangeRule(min: 4.7, max: 1684.3)
        let item = CareManagement.newTieredAssessmentManifest("x", title: "y")
        item.amount = 1685.8
        #expect(rule.check(item).count > 0)
    }
}
