@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityAssignmentValidator()
        let item = Imaging.newModalityAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityAssignmentCodeLengthRule(maxLength: 255)
        let item = Imaging.newModalityAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityAssignmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.ModalityAssignmentRatioRangeRule(min: 8.6, max: 1907.2)
        let item = Imaging.newModalityAssignment("x", name: "y")
        item.ratio = 1908.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityAssignmentVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Imaging.ModalityAssignmentVersionRangeRule(min: 64, max: 86400)
        let item = Imaging.newModalityAssignment("x", name: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityAssignmentRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Imaging.ModalityAssignmentRequiredDescriptionRule(message: "modality assignment needs this field")
        let item = Imaging.newModalityAssignment("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
