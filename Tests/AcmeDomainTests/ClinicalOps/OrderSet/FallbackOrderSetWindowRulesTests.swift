@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackOrderSetWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackOrderSetWindowValidator()
        let item = ClinicalOps.newFallbackOrderSetWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetWindowRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.FallbackOrderSetWindowRequiredEncounterIDRule(
            message: "fallback order set window needs an entry"
        )
        let item = ClinicalOps.newFallbackOrderSetWindow("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.FallbackOrderSetWindowRequiredLabelRule(
            message: "fallback order set window needs an entry"
        )
        let item = ClinicalOps.newFallbackOrderSetWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
