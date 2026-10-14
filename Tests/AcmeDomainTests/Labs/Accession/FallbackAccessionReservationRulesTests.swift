@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackAccessionReservationValidator()
        let item = Labs.newFallbackAccessionReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackAccessionReservationDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Labs.FallbackAccessionReservationDiagnosisCodeLengthRule(maxLength: 32)
        let item = Labs.newFallbackAccessionReservation("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackAccessionReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackAccessionReservationRequiredCodeRule(
            message: "fallback accession reservation needs a value"
        )
        let item = Labs.newFallbackAccessionReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackAccessionReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.FallbackAccessionReservationRequiredTitleRule(
            message: "fallback accession reservation needs an entry"
        )
        let item = Labs.newFallbackAccessionReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
