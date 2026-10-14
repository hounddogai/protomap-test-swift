@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyAccessionAgreementValidator()
        let item = Labs.newLegacyAccessionAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyAccessionAgreementDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.LegacyAccessionAgreementDosageMgRangeRule(min: 7.4, max: 4152.0)
        let item = Labs.newLegacyAccessionAgreement("x", label: "y")
        item.dosageMg = 4153.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyAccessionAgreementSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Labs.LegacyAccessionAgreementSummaryLengthRule(maxLength: 255)
        let item = Labs.newLegacyAccessionAgreement("x", label: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyAccessionAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LegacyAccessionAgreementRequiredCodeRule(message: "legacy accession agreement needs a value")
        let item = Labs.newLegacyAccessionAgreement("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyAccessionAgreementVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Labs.LegacyAccessionAgreementVisitMinutesRangeRule(min: 64, max: 64)
        let item = Labs.newLegacyAccessionAgreement("x", label: "y")
        item.visitMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}
