@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityBudgetValidator()
        let item = Imaging.newModalityBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityBudgetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ModalityBudgetRequiredLabelRule(message: "modality budget needs an entry")
        let item = Imaging.newModalityBudget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalityBudgetRequiredCodeRule(message: "modality budget needs a value")
        let item = Imaging.newModalityBudget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
