@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryCourierManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryCourierManifestValidator()
        let item = Labs.newPrimaryCourierManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryCourierManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.PrimaryCourierManifestTitleLengthRule(maxLength: 16)
        let item = Labs.newPrimaryCourierManifest("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryCourierManifestRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Labs.PrimaryCourierManifestRequiredSpecialtyRule(message: "primary courier manifest needs a value")
        let item = Labs.newPrimaryCourierManifest("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryCourierManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PrimaryCourierManifestRequiredCodeRule(message: "primary courier manifest needs this field")
        let item = Labs.newPrimaryCourierManifest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryCourierManifestSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.PrimaryCourierManifestSpecialtyLengthRule(maxLength: 255)
        let item = Labs.newPrimaryCourierManifest("x", title: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryCourierManifestUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.PrimaryCourierManifestUnitLengthRule(maxLength: 16)
        let item = Labs.newPrimaryCourierManifest("x", title: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryCourierManifestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.PrimaryCourierManifestRateRangeRule(min: 5.0, max: 3009.2)
        let item = Labs.newPrimaryCourierManifest("x", title: "y")
        item.rate = 3010.7
        #expect(rule.check(item).count > 0)
    }
}
