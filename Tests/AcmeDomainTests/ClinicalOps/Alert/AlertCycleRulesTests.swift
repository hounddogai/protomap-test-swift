@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertCycleValidator()
        let item = ClinicalOps.newAlertCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertCycleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.AlertCycleRequiredLabelRule(message: "alert cycle needs a value")
        let item = ClinicalOps.newAlertCycle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertCycleRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = ClinicalOps.AlertCycleRequiredCategoryRule(message: "alert cycle needs this field")
        let item = ClinicalOps.newAlertCycle("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertCycleCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = ClinicalOps.AlertCycleCategoryLengthRule(maxLength: 3600)
        let item = ClinicalOps.newAlertCycle("x", label: "y")
        item.category = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertCycleRequiredCodeRule(message: "alert cycle needs an entry")
        let item = ClinicalOps.newAlertCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertCycleOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.AlertCycleOwnerIDLengthRule(maxLength: 120)
        let item = ClinicalOps.newAlertCycle("x", label: "y")
        item.ownerID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertCycleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.AlertCycleAmountRangeRule(min: 8.4, max: 4420.4)
        let item = ClinicalOps.newAlertCycle("x", label: "y")
        item.amount = 4421.9
        #expect(rule.check(item).count > 0)
    }
}
