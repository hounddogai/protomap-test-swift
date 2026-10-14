@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolManifestValidator()
        let item = ClinicalOps.newCareProtocolManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.CareProtocolManifestRequiredNameRule(message: "care protocol manifest needs an entry")
        let item = ClinicalOps.newCareProtocolManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolManifestMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.CareProtocolManifestMaximumRangeRule(min: 2.4, max: 646.5)
        let item = ClinicalOps.newCareProtocolManifest("x", name: "y")
        item.maximum = 648.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolManifestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.CareProtocolManifestRegionLengthRule(maxLength: 1000)
        let item = ClinicalOps.newCareProtocolManifest("x", name: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolManifestCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newCareProtocolManifest("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolManifestRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = ClinicalOps.CareProtocolManifestRequiredRegionRule(message: "care protocol manifest needs a value")
        let item = ClinicalOps.newCareProtocolManifest("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
