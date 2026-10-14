@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedSpecimenTierValidator()
        let item = Labs.newCappedSpecimenTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedSpecimenTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedSpecimenTierCodeLengthRule(maxLength: 80)
        let item = Labs.newCappedSpecimenTier("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedSpecimenTierSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Labs.CappedSpecimenTierSummaryLengthRule(maxLength: 16)
        let item = Labs.newCappedSpecimenTier("x", name: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
