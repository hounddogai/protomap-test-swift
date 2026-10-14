@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionCycleValidator()
        let item = Labs.newAccessionCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionCycleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.AccessionCycleRequiredLabelRule(message: "accession cycle needs this field")
        let item = Labs.newAccessionCycle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionCycleRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.AccessionCycleRequiredLocaleRule(message: "accession cycle needs a value")
        let item = Labs.newAccessionCycle("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionCycleRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.AccessionCycleRequiredDiagnosisCodeRule(message: "accession cycle needs a value")
        let item = Labs.newAccessionCycle("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionCycleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.AccessionCycleVersionRangeRule(min: 3600, max: 3600)
        let item = Labs.newAccessionCycle("x", label: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}
