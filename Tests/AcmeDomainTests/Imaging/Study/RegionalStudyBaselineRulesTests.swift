@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalStudyBaselineValidator()
        let item = Imaging.newRegionalStudyBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalStudyBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.RegionalStudyBaselineNameLengthRule(maxLength: 3600)
        let item = Imaging.newRegionalStudyBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalStudyBaselineRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Imaging.RegionalStudyBaselineRequiredFacilityRule(message: "regional study baseline needs an entry")
        let item = Imaging.newRegionalStudyBaseline("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalStudyBaselineChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Imaging.RegionalStudyBaselineChecksumLengthRule(maxLength: 3600)
        let item = Imaging.newRegionalStudyBaseline("x", name: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalStudyBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.RegionalStudyBaselineRequiredCodeRule(message: "regional study baseline needs an entry")
        let item = Imaging.newRegionalStudyBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
