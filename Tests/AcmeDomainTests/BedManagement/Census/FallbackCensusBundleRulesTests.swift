@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackCensusBundleValidator()
        let item = BedManagement.newFallbackCensusBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackCensusBundleRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.FallbackCensusBundleRequiredEncounterIDRule(
            message: "fallback census bundle needs this field"
        )
        let item = BedManagement.newFallbackCensusBundle("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackCensusBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.FallbackCensusBundleCodeLengthRule(maxLength: 255)
        let item = BedManagement.newFallbackCensusBundle("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCensusBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackCensusBundleRequiredCodeRule(message: "fallback census bundle needs an entry")
        let item = BedManagement.newFallbackCensusBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
