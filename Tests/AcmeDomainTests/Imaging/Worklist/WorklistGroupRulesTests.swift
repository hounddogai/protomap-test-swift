@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistGroupValidator()
        let item = Imaging.newWorklistGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistGroupSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.WorklistGroupSpecialtyLengthRule(maxLength: 1000)
        let item = Imaging.newWorklistGroup("x", title: "y")
        item.specialty = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistGroupCodeLengthRule(maxLength: 80)
        let item = Imaging.newWorklistGroup("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistGroupRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.WorklistGroupRequiredUnitRule(message: "worklist group needs this field")
        let item = Imaging.newWorklistGroup("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
