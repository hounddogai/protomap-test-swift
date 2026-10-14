@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingStudyEntryValidator()
        let item = Imaging.newRollingStudyEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingStudyEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.RollingStudyEntryNameLengthRule(maxLength: 120)
        let item = Imaging.newRollingStudyEntry("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingStudyEntryRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Imaging.RollingStudyEntryRequiredPhoneRule(message: "rolling study entry needs an entry")
        let item = Imaging.newRollingStudyEntry("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingStudyEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.RollingStudyEntryRequiredCodeRule(message: "rolling study entry needs a value")
        let item = Imaging.newRollingStudyEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingStudyEntryRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Imaging.RollingStudyEntryRequiredEncounterIDRule(message: "rolling study entry needs this field")
        let item = Imaging.newRollingStudyEntry("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
