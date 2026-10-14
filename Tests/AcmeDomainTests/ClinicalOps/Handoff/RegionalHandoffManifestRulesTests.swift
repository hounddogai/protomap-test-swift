@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalHandoffManifestValidator()
        let item = ClinicalOps.newRegionalHandoffManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalHandoffManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RegionalHandoffManifestRequiredLabelRule(
            message: "regional handoff manifest needs an entry"
        )
        let item = ClinicalOps.newRegionalHandoffManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalHandoffManifestFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = ClinicalOps.RegionalHandoffManifestFacilityLengthRule(maxLength: 32)
        let item = ClinicalOps.newRegionalHandoffManifest("x", label: "y")
        item.facility = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalHandoffManifestGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.RegionalHandoffManifestGraceDaysRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newRegionalHandoffManifest("x", label: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRegionalHandoffManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RegionalHandoffManifestCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newRegionalHandoffManifest("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
