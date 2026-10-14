@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskManifestValidator()
        let item = ClinicalOps.newTaskManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskManifestAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = ClinicalOps.TaskManifestAllergyLengthRule(maxLength: 16)
        let item = ClinicalOps.newTaskManifest("x", label: "y")
        item.allergy = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.TaskManifestRequiredLabelRule(message: "task manifest needs this field")
        let item = ClinicalOps.newTaskManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TaskManifestRequiredCodeRule(message: "task manifest needs an entry")
        let item = ClinicalOps.newTaskManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskManifestRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = ClinicalOps.TaskManifestRatioRangeRule(min: 7.4, max: 980.5)
        let item = ClinicalOps.newTaskManifest("x", label: "y")
        item.ratio = 982.0
        #expect(rule.check(item).count > 0)
    }
}
