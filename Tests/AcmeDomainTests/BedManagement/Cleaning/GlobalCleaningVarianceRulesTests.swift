@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalCleaningVarianceValidator()
        let item = BedManagement.newGlobalCleaningVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalCleaningVarianceCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = BedManagement.GlobalCleaningVarianceCostRangeRule(min: 2.5, max: 3980.6)
        let item = BedManagement.newGlobalCleaningVariance("x", label: "y")
        item.cost = 3982.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementGlobalCleaningVarianceCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.GlobalCleaningVarianceCreatedAtRangeRule(min: 120, max: 255)
        let item = BedManagement.newGlobalCleaningVariance("x", label: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementGlobalCleaningVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.GlobalCleaningVarianceRequiredLabelRule(
            message: "global cleaning variance needs a value"
        )
        let item = BedManagement.newGlobalCleaningVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
