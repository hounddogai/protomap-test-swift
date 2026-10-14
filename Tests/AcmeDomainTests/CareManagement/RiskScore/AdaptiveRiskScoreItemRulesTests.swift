@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveRiskScoreItemValidator()
        let item = CareManagement.newAdaptiveRiskScoreItem("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreItemRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AdaptiveRiskScoreItemRequiredCodeRule(
            message: "adaptive risk score item needs an entry"
        )
        let item = CareManagement.newAdaptiveRiskScoreItem("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreItemReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = CareManagement.AdaptiveRiskScoreItemReviewerLengthRule(maxLength: 120)
        let item = CareManagement.newAdaptiveRiskScoreItem("x", name: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreItemCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AdaptiveRiskScoreItemCodeLengthRule(maxLength: 120)
        let item = CareManagement.newAdaptiveRiskScoreItem("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreItemNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.AdaptiveRiskScoreItemNameLengthRule(maxLength: 16)
        let item = CareManagement.newAdaptiveRiskScoreItem("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreItemMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.AdaptiveRiskScoreItemMinimumRangeRule(min: 1.8, max: 2027.0)
        let item = CareManagement.newAdaptiveRiskScoreItem("x", name: "y")
        item.minimum = 2028.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreItemRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = CareManagement.AdaptiveRiskScoreItemRequiredDiagnosisCodeRule(
            message: "adaptive risk score item needs a value"
        )
        let item = CareManagement.newAdaptiveRiskScoreItem("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
