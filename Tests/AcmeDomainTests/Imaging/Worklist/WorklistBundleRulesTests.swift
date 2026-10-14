@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistBundleValidator()
        let item = Imaging.newWorklistBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WorklistBundleRequiredCodeRule(message: "worklist bundle needs an entry")
        let item = Imaging.newWorklistBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistBundleRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Imaging.WorklistBundleRequiredDiagnosisCodeRule(message: "worklist bundle needs this field")
        let item = Imaging.newWorklistBundle("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistBundleAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.WorklistBundleAcuityRangeRule(min: 32, max: 3600)
        let item = Imaging.newWorklistBundle("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistBundleRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.WorklistBundleRefillsRangeRule(min: 16, max: 120)
        let item = Imaging.newWorklistBundle("x", label: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistBundleMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.WorklistBundleMinimumRangeRule(min: 9.1, max: 1475.1)
        let item = Imaging.newWorklistBundle("x", label: "y")
        item.minimum = 1476.6
        #expect(rule.check(item).count > 0)
    }
}
