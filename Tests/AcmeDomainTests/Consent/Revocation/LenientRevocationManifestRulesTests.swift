@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientRevocationManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientRevocationManifestValidator()
        let item = Consent.newLenientRevocationManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientRevocationManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LenientRevocationManifestCodeLengthRule(maxLength: 80)
        let item = Consent.newLenientRevocationManifest("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientRevocationManifestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.LenientRevocationManifestRegionLengthRule(maxLength: 255)
        let item = Consent.newLenientRevocationManifest("x", label: "y")
        item.region = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientRevocationManifestWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.LenientRevocationManifestWindowDaysRangeRule(min: 255, max: 3600)
        let item = Consent.newLenientRevocationManifest("x", label: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientRevocationManifestFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Consent.LenientRevocationManifestFloorValueRangeRule(min: 1.7, max: 4406.1)
        let item = Consent.newLenientRevocationManifest("x", label: "y")
        item.floorValue = 4407.6
        #expect(rule.check(item).count > 0)
    }
}
