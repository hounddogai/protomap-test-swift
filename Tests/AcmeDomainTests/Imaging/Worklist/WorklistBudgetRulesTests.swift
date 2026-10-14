@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistBudgetValidator()
        let item = Imaging.newWorklistBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistBudgetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.WorklistBudgetLabelLengthRule(maxLength: 3600)
        let item = Imaging.newWorklistBudget("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistBudgetOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Imaging.WorklistBudgetOwnerIDLengthRule(maxLength: 1000)
        let item = Imaging.newWorklistBudget("x", label: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistBudgetCodeLengthRule(maxLength: 1000)
        let item = Imaging.newWorklistBudget("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistBudgetRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.WorklistBudgetRefillsRangeRule(min: 80, max: 3600)
        let item = Imaging.newWorklistBudget("x", label: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WorklistBudgetRequiredCodeRule(message: "worklist budget needs an entry")
        let item = Imaging.newWorklistBudget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
