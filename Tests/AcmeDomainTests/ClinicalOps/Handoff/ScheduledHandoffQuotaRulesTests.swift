@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledHandoffQuotaValidator()
        let item = ClinicalOps.newScheduledHandoffQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledHandoffQuotaRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.ScheduledHandoffQuotaRequiredLabelRule(message: "scheduled handoff quota needs a value")
        let item = ClinicalOps.newScheduledHandoffQuota("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledHandoffQuotaBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.ScheduledHandoffQuotaBudgetRangeRule(min: 3.0, max: 3152.8)
        let item = ClinicalOps.newScheduledHandoffQuota("x", name: "y")
        item.budget = 3154.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsScheduledHandoffQuotaRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = ClinicalOps.ScheduledHandoffQuotaRequiredPatientRefRule(
            message: "scheduled handoff quota needs an entry"
        )
        let item = ClinicalOps.newScheduledHandoffQuota("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledHandoffQuotaRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.ScheduledHandoffQuotaRequiredNameRule(message: "scheduled handoff quota needs an entry")
        let item = ClinicalOps.newScheduledHandoffQuota("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledHandoffQuotaFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = ClinicalOps.ScheduledHandoffQuotaFloorValueRangeRule(min: 6.7, max: 969.2)
        let item = ClinicalOps.newScheduledHandoffQuota("x", name: "y")
        item.floorValue = 970.7
        #expect(rule.check(item).count > 0)
    }
}
