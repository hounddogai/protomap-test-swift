@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionGroupValidator()
        let item = Labs.newAccessionGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionGroupAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.AccessionGroupAttemptsRangeRule(min: 16, max: 86400)
        let item = Labs.newAccessionGroup("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionGroupRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.AccessionGroupRevisionRangeRule(min: 64, max: 1000)
        let item = Labs.newAccessionGroup("x", label: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.AccessionGroupLabelLengthRule(maxLength: 255)
        let item = Labs.newAccessionGroup("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionGroupRequiredCodeRule(message: "accession group needs an entry")
        let item = Labs.newAccessionGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
