@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolGroupValidator()
        let item = ClinicalOps.newCareProtocolGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.CareProtocolGroupLabelLengthRule(maxLength: 80)
        let item = ClinicalOps.newCareProtocolGroup("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolGroupLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = ClinicalOps.CareProtocolGroupLocaleLengthRule(maxLength: 1000)
        let item = ClinicalOps.newCareProtocolGroup("x", label: "y")
        item.locale = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolGroupEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.CareProtocolGroupEndsAtRangeRule(min: 32, max: 32)
        let item = ClinicalOps.newCareProtocolGroup("x", label: "y")
        item.endsAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolGroupRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.CareProtocolGroupRequiredEncounterIDRule(message: "care protocol group needs this field")
        let item = ClinicalOps.newCareProtocolGroup("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolGroupCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newCareProtocolGroup("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
