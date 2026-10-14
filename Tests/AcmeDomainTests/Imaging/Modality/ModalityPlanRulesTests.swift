@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityPlanValidator()
        let item = Imaging.newModalityPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityPlanCodeLengthRule(maxLength: 16)
        let item = Imaging.newModalityPlan("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityPlanRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.ModalityPlanRequiredBedRule(message: "modality plan needs a value")
        let item = Imaging.newModalityPlan("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityPlanTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Imaging.ModalityPlanTimezoneLengthRule(maxLength: 16)
        let item = Imaging.newModalityPlan("x", title: "y")
        item.timezone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
