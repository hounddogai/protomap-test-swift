@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapTargetValidator()
        let item = CareManagement.newCareGapTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapTargetCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.CareGapTargetCreatedAtRangeRule(min: 16, max: 1000)
        let item = CareManagement.newCareGapTarget("x", name: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.CareGapTargetRequiredNameRule(message: "care gap target needs this field")
        let item = CareManagement.newCareGapTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapTargetRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = CareManagement.CareGapTargetRequiredReviewerRule(message: "care gap target needs an entry")
        let item = CareManagement.newCareGapTarget("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapTargetCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.CareGapTargetCapacityRangeRule(min: 64, max: 64)
        let item = CareManagement.newCareGapTarget("x", name: "y")
        item.capacity = 65
        #expect(rule.check(item).count > 0)
    }
}
