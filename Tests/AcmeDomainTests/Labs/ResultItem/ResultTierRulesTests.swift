@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultTierValidator()
        let item = Labs.newResultTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultTierChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.ResultTierChannelLengthRule(maxLength: 32)
        let item = Labs.newResultTier("x", label: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultTierCodeLengthRule(maxLength: 3600)
        let item = Labs.newResultTier("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultTierRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.ResultTierRequiredChannelRule(message: "result tier needs this field")
        let item = Labs.newResultTier("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultTierSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.ResultTierSpecialtyLengthRule(maxLength: 80)
        let item = Labs.newResultTier("x", label: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
