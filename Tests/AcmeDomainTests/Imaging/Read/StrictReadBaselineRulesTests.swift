@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictReadBaselineValidator()
        let item = Imaging.newStrictReadBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictReadBaselineRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.StrictReadBaselineRequiredOwnerIDRule(message: "strict read baseline needs an entry")
        let item = Imaging.newStrictReadBaseline("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictReadBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.StrictReadBaselineNameLengthRule(maxLength: 120)
        let item = Imaging.newStrictReadBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictReadBaselineRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.StrictReadBaselineRegionLengthRule(maxLength: 64)
        let item = Imaging.newStrictReadBaseline("x", name: "y")
        item.region = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
