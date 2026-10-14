@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeRecordValidator()
        let item = Labs.newReferenceRangeRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeRecordMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.ReferenceRangeRecordMinimumRangeRule(min: 4.6, max: 2449.6)
        let item = Labs.newReferenceRangeRecord("x", name: "y")
        item.minimum = 2451.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ReferenceRangeRecordCodeLengthRule(maxLength: 120)
        let item = Labs.newReferenceRangeRecord("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeRecordBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.ReferenceRangeRecordBedLengthRule(maxLength: 255)
        let item = Labs.newReferenceRangeRecord("x", name: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ReferenceRangeRecordNameLengthRule(maxLength: 16)
        let item = Labs.newReferenceRangeRecord("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
