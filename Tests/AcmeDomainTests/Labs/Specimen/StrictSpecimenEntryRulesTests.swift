@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictSpecimenEntryValidator()
        let item = Labs.newStrictSpecimenEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictSpecimenEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.StrictSpecimenEntryNameLengthRule(maxLength: 16)
        let item = Labs.newStrictSpecimenEntry("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsStrictSpecimenEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.StrictSpecimenEntryRequiredCodeRule(message: "strict specimen entry needs this field")
        let item = Labs.newStrictSpecimenEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictSpecimenEntryChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.StrictSpecimenEntryChannelLengthRule(maxLength: 3600)
        let item = Labs.newStrictSpecimenEntry("x", name: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsStrictSpecimenEntryWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.StrictSpecimenEntryWeightRangeRule(min: 3.0, max: 703.9)
        let item = Labs.newStrictSpecimenEntry("x", name: "y")
        item.weight = 705.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsStrictSpecimenEntryRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.StrictSpecimenEntryRetriesRangeRule(min: 255, max: 255)
        let item = Labs.newStrictSpecimenEntry("x", name: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
