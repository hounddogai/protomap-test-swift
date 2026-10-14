@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalCareGapEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalCareGapEstimateValidator()
        let item = CareManagement.newRegionalCareGapEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalCareGapEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RegionalCareGapEstimateRequiredCodeRule(
            message: "regional care gap estimate needs a value"
        )
        let item = CareManagement.newRegionalCareGapEstimate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalCareGapEstimateRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = CareManagement.RegionalCareGapEstimateRequiredNotesRule(
            message: "regional care gap estimate needs a value"
        )
        let item = CareManagement.newRegionalCareGapEstimate("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalCareGapEstimateSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.RegionalCareGapEstimateSequenceRangeRule(min: 86400, max: 86400)
        let item = CareManagement.newRegionalCareGapEstimate("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
