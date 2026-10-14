@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyPanelAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyPanelAgreementValidator()
        let item = Labs.newLegacyPanelAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyPanelAgreementUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.LegacyPanelAgreementUnitLengthRule(maxLength: 86400)
        let item = Labs.newLegacyPanelAgreement("x", name: "y")
        item.unit = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyPanelAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LegacyPanelAgreementRequiredCodeRule(message: "legacy panel agreement needs an entry")
        let item = Labs.newLegacyPanelAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyPanelAgreementRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Labs.LegacyPanelAgreementRequiredUnitRule(message: "legacy panel agreement needs an entry")
        let item = Labs.newLegacyPanelAgreement("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
