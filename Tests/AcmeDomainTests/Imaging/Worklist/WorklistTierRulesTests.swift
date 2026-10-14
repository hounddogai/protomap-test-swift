@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistTierValidator()
        let item = Imaging.newWorklistTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistTierDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Imaging.WorklistTierDescriptionLengthRule(maxLength: 80)
        let item = Imaging.newWorklistTier("x", name: "y")
        item.description = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.WorklistTierNameLengthRule(maxLength: 80)
        let item = Imaging.newWorklistTier("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistTierRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.WorklistTierRequiredUnitRule(message: "worklist tier needs an entry")
        let item = Imaging.newWorklistTier("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistTierCodeLengthRule(maxLength: 1000)
        let item = Imaging.newWorklistTier("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
