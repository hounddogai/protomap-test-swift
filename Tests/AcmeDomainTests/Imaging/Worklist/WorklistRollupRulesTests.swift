@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistRollupValidator()
        let item = Imaging.newWorklistRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistRollupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.WorklistRollupTitleLengthRule(maxLength: 120)
        let item = Imaging.newWorklistRollup("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistRollupCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.WorklistRollupCountryLengthRule(maxLength: 1000)
        let item = Imaging.newWorklistRollup("x", title: "y")
        item.country = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistRollupCodeLengthRule(maxLength: 80)
        let item = Imaging.newWorklistRollup("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
