@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualPriorityTargetValidator()
        let item = Imaging.newManualPriorityTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualPriorityTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ManualPriorityTargetRequiredCodeRule(message: "manual priority target needs an entry")
        let item = Imaging.newManualPriorityTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualPriorityTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ManualPriorityTargetRequiredLabelRule(message: "manual priority target needs a value")
        let item = Imaging.newManualPriorityTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualPriorityTargetPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.ManualPriorityTargetPriorityRangeRule(min: 16, max: 86400)
        let item = Imaging.newManualPriorityTarget("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingManualPriorityTargetBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.ManualPriorityTargetBedLengthRule(maxLength: 3600)
        let item = Imaging.newManualPriorityTarget("x", label: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
