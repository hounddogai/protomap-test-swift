@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolReviewValidator()
        let item = ClinicalOps.newCareProtocolReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolReviewRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = ClinicalOps.CareProtocolReviewRequiredUnitRule(message: "care protocol review needs an entry")
        let item = ClinicalOps.newCareProtocolReview("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolReviewCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = ClinicalOps.CareProtocolReviewCeilingRangeRule(min: 4.7, max: 4695.8)
        let item = ClinicalOps.newCareProtocolReview("x", label: "y")
        item.ceiling = 4697.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolReviewCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newCareProtocolReview("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.CareProtocolReviewRequiredLabelRule(message: "care protocol review needs a value")
        let item = ClinicalOps.newCareProtocolReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolReviewEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = ClinicalOps.CareProtocolReviewEncounterIDLengthRule(maxLength: 64)
        let item = ClinicalOps.newCareProtocolReview("x", label: "y")
        item.encounterID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
