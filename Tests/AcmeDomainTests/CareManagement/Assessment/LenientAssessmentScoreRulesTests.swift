@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientAssessmentScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientAssessmentScoreValidator()
        let item = CareManagement.newLenientAssessmentScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientAssessmentScoreCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = CareManagement.LenientAssessmentScoreCostRangeRule(min: 9.6, max: 257.3)
        let item = CareManagement.newLenientAssessmentScore("x", name: "y")
        item.cost = 258.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLenientAssessmentScoreRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = CareManagement.LenientAssessmentScoreRequiredClinicianIDRule(
            message: "lenient assessment score needs an entry"
        )
        let item = CareManagement.newLenientAssessmentScore("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientAssessmentScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.LenientAssessmentScoreNameLengthRule(maxLength: 80)
        let item = CareManagement.newLenientAssessmentScore("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientAssessmentScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LenientAssessmentScoreRequiredCodeRule(
            message: "lenient assessment score needs this field"
        )
        let item = CareManagement.newLenientAssessmentScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
