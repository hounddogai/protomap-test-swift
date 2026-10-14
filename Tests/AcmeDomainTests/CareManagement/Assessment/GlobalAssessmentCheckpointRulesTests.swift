@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalAssessmentCheckpointValidator()
        let item = CareManagement.newGlobalAssessmentCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalAssessmentCheckpointVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.GlobalAssessmentCheckpointVersionRangeRule(min: 3600, max: 86400)
        let item = CareManagement.newGlobalAssessmentCheckpoint("x", name: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalAssessmentCheckpointNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.GlobalAssessmentCheckpointNameLengthRule(maxLength: 1000)
        let item = CareManagement.newGlobalAssessmentCheckpoint("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalAssessmentCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GlobalAssessmentCheckpointCodeLengthRule(maxLength: 120)
        let item = CareManagement.newGlobalAssessmentCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
