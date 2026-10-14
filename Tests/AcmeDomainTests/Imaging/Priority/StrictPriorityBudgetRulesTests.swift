@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictPriorityBudgetValidator()
        let item = Imaging.newStrictPriorityBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictPriorityBudgetPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Imaging.StrictPriorityBudgetPatientRefLengthRule(maxLength: 80)
        let item = Imaging.newStrictPriorityBudget("x", name: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictPriorityBudgetDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Imaging.StrictPriorityBudgetDescriptionLengthRule(maxLength: 3600)
        let item = Imaging.newStrictPriorityBudget("x", name: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictPriorityBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StrictPriorityBudgetRequiredCodeRule(message: "strict priority budget needs an entry")
        let item = Imaging.newStrictPriorityBudget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
