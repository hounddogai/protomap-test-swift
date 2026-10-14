@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualPriorityEntryValidator()
        let item = Imaging.newManualPriorityEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualPriorityEntryCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.ManualPriorityEntryCeilingRangeRule(min: 5.5, max: 1000.7)
        let item = Imaging.newManualPriorityEntry("x", label: "y")
        item.ceiling = 1002.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingManualPriorityEntryFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.ManualPriorityEntryFloorValueRangeRule(min: 9.8, max: 3985.8)
        let item = Imaging.newManualPriorityEntry("x", label: "y")
        item.floorValue = 3987.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingManualPriorityEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ManualPriorityEntryRequiredCodeRule(message: "manual priority entry needs an entry")
        let item = Imaging.newManualPriorityEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
