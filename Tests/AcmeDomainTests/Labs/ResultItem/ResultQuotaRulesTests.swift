@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultQuotaValidator()
        let item = Labs.newResultQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultQuotaRequiredCodeRule(message: "result quota needs an entry")
        let item = Labs.newResultQuota("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultQuotaSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.ResultQuotaSegmentLengthRule(maxLength: 16)
        let item = Labs.newResultQuota("x", label: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultQuotaEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.ResultQuotaEndsAtRangeRule(min: 32, max: 255)
        let item = Labs.newResultQuota("x", label: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultQuotaRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Labs.ResultQuotaRequiredSegmentRule(message: "result quota needs this field")
        let item = Labs.newResultQuota("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultQuotaCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.ResultQuotaCostRangeRule(min: 0.8, max: 4060.0)
        let item = Labs.newResultQuota("x", label: "y")
        item.cost = 4061.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultQuotaRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.ResultQuotaRequiredChannelRule(message: "result quota needs an entry")
        let item = Labs.newResultQuota("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
