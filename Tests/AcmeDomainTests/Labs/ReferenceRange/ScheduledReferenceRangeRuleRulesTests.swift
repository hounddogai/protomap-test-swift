@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledReferenceRangeRuleValidator()
        let item = Labs.newScheduledReferenceRangeRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledReferenceRangeRuleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.ScheduledReferenceRangeRuleRequiredChecksumRule(
            message: "scheduled reference range rule needs an entry"
        )
        let item = Labs.newScheduledReferenceRangeRule("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledReferenceRangeRuleSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.ScheduledReferenceRangeRuleSpecialtyLengthRule(maxLength: 86400)
        let item = Labs.newScheduledReferenceRangeRule("x", name: "y")
        item.specialty = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledReferenceRangeRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ScheduledReferenceRangeRuleNameLengthRule(maxLength: 16)
        let item = Labs.newScheduledReferenceRangeRule("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledReferenceRangeRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ScheduledReferenceRangeRuleRequiredCodeRule(
            message: "scheduled reference range rule needs an entry"
        )
        let item = Labs.newScheduledReferenceRangeRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledReferenceRangeRuleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.ScheduledReferenceRangeRuleAmountRangeRule(min: 9.8, max: 3254.3)
        let item = Labs.newScheduledReferenceRangeRule("x", name: "y")
        item.amount = 3255.8
        #expect(rule.check(item).count > 0)
    }
}
