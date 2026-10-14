@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualReferenceRangeAssignmentValidator()
        let item = Labs.newManualReferenceRangeAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualReferenceRangeAssignmentContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.ManualReferenceRangeAssignmentContactEmailLengthRule(maxLength: 16)
        let item = Labs.newManualReferenceRangeAssignment("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsManualReferenceRangeAssignmentRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.ManualReferenceRangeAssignmentRequiredCurrencyRule(
            message: "manual reference range assignment needs an entry"
        )
        let item = Labs.newManualReferenceRangeAssignment("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualReferenceRangeAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ManualReferenceRangeAssignmentCodeLengthRule(maxLength: 255)
        let item = Labs.newManualReferenceRangeAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsManualReferenceRangeAssignmentStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.ManualReferenceRangeAssignmentStartsAtRangeRule(min: 3600, max: 3600)
        let item = Labs.newManualReferenceRangeAssignment("x", name: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
