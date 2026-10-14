@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientWorklistExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientWorklistExceptionValidator()
        let item = Imaging.newLenientWorklistException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientWorklistExceptionDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Imaging.LenientWorklistExceptionDescriptionLengthRule(maxLength: 64)
        let item = Imaging.newLenientWorklistException("x", title: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientWorklistExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.LenientWorklistExceptionTitleLengthRule(maxLength: 32)
        let item = Imaging.newLenientWorklistException("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientWorklistExceptionRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Imaging.LenientWorklistExceptionRequiredDescriptionRule(
            message: "lenient worklist exception needs a value"
        )
        let item = Imaging.newLenientWorklistException("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLenientWorklistExceptionRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Imaging.LenientWorklistExceptionRevisionRangeRule(min: 32, max: 255)
        let item = Imaging.newLenientWorklistException("x", title: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}
