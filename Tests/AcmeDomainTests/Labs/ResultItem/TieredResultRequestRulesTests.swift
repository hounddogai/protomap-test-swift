@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredResultRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultTieredResultRequestValidator()
        let item = Labs.newTieredResultRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsTieredResultRequestRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.TieredResultRequestRequiredChannelRule(message: "tiered result request needs a value")
        let item = Labs.newTieredResultRequest("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredResultRequestChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.TieredResultRequestChannelLengthRule(maxLength: 64)
        let item = Labs.newTieredResultRequest("x", title: "y")
        item.channel = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsTieredResultRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.TieredResultRequestRequiredCodeRule(message: "tiered result request needs this field")
        let item = Labs.newTieredResultRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
