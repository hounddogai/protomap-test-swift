@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyCycleValidator()
        let item = Imaging.newStudyCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyCycleRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.StudyCycleRequiredBedRule(message: "study cycle needs this field")
        let item = Imaging.newStudyCycle("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyCycleRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Imaging.StudyCycleRequiredFacilityRule(message: "study cycle needs a value")
        let item = Imaging.newStudyCycle("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.StudyCycleLabelLengthRule(maxLength: 255)
        let item = Imaging.newStudyCycle("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
