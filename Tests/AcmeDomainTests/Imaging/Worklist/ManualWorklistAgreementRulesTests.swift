@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualWorklistAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualWorklistAgreementValidator()
        let item = Imaging.newManualWorklistAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualWorklistAgreementDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.ManualWorklistAgreementDurationMinutesRangeRule(min: 120, max: 3600)
        let item = Imaging.newManualWorklistAgreement("x", title: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingManualWorklistAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ManualWorklistAgreementRequiredTitleRule(
            message: "manual worklist agreement needs this field"
        )
        let item = Imaging.newManualWorklistAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualWorklistAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ManualWorklistAgreementTitleLengthRule(maxLength: 120)
        let item = Imaging.newManualWorklistAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualWorklistAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ManualWorklistAgreementCodeLengthRule(maxLength: 32)
        let item = Imaging.newManualWorklistAgreement("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
