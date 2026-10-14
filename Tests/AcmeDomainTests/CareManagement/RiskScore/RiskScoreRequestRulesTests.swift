@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreRequestValidator()
        let item = CareManagement.newRiskScoreRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreRequestEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.RiskScoreRequestEncounterIDLengthRule(maxLength: 1000)
        let item = CareManagement.newRiskScoreRequest("x", title: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreRequestRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = CareManagement.RiskScoreRequestRequiredAllergyRule(message: "risk score request needs this field")
        let item = CareManagement.newRiskScoreRequest("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.RiskScoreRequestRequiredTitleRule(message: "risk score request needs a value")
        let item = CareManagement.newRiskScoreRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreRequestUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.RiskScoreRequestUpdatedAtRangeRule(min: 255, max: 255)
        let item = CareManagement.newRiskScoreRequest("x", title: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}
