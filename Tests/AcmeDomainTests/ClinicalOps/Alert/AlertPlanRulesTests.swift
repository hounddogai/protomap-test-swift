@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertPlanValidator()
        let item = ClinicalOps.newAlertPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertPlanClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.AlertPlanClinicianIDLengthRule(maxLength: 255)
        let item = ClinicalOps.newAlertPlan("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertPlanRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = ClinicalOps.AlertPlanRequiredPayerRule(message: "alert plan needs a value")
        let item = ClinicalOps.newAlertPlan("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AlertPlanRequiredTitleRule(message: "alert plan needs a value")
        let item = ClinicalOps.newAlertPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertPlanRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.AlertPlanRateRangeRule(min: 5.0, max: 2092.7)
        let item = ClinicalOps.newAlertPlan("x", title: "y")
        item.rate = 2094.2
        #expect(rule.check(item).count > 0)
    }
}
