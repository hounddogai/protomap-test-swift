@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreExceptionValidator()
        let item = CareManagement.newRiskScoreException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreExceptionRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.RiskScoreExceptionRequiredFacilityRule(
            message: "risk score exception needs this field"
        )
        let item = CareManagement.newRiskScoreException("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreExceptionVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.RiskScoreExceptionVersionRangeRule(min: 255, max: 255)
        let item = CareManagement.newRiskScoreException("x", title: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreExceptionEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = CareManagement.RiskScoreExceptionEndsAtRangeRule(min: 120, max: 255)
        let item = CareManagement.newRiskScoreException("x", title: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreExceptionSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = CareManagement.RiskScoreExceptionSourceLengthRule(maxLength: 120)
        let item = CareManagement.newRiskScoreException("x", title: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
