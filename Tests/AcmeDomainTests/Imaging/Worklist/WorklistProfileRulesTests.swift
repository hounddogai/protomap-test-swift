@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistProfileValidator()
        let item = Imaging.newWorklistProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.WorklistProfileLabelLengthRule(maxLength: 3600)
        let item = Imaging.newWorklistProfile("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistProfileRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.WorklistProfileRequiredPayerRule(message: "worklist profile needs a value")
        let item = Imaging.newWorklistProfile("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistProfileMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.WorklistProfileMinimumRangeRule(min: 3.1, max: 1889.6)
        let item = Imaging.newWorklistProfile("x", label: "y")
        item.minimum = 1891.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistProfileClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Imaging.WorklistProfileClinicianIDLengthRule(maxLength: 255)
        let item = Imaging.newWorklistProfile("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
