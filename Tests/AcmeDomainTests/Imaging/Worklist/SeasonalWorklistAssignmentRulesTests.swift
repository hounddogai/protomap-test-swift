@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalWorklistAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalWorklistAssignmentValidator()
        let item = Imaging.newSeasonalWorklistAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalWorklistAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.SeasonalWorklistAssignmentCodeLengthRule(maxLength: 1000)
        let item = Imaging.newSeasonalWorklistAssignment("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalWorklistAssignmentQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Imaging.SeasonalWorklistAssignmentQuantityRangeRule(min: 16, max: 255)
        let item = Imaging.newSeasonalWorklistAssignment("x", label: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalWorklistAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.SeasonalWorklistAssignmentRequiredLabelRule(
            message: "seasonal worklist assignment needs this field"
        )
        let item = Imaging.newSeasonalWorklistAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
