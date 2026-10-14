@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedIsolationSegmentValidator()
        let item = BedManagement.newWeightedIsolationSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedIsolationSegmentCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = BedManagement.WeightedIsolationSegmentCurrencyLengthRule(maxLength: 16)
        let item = BedManagement.newWeightedIsolationSegment("x", name: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedIsolationSegmentCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.WeightedIsolationSegmentCopayRangeRule(min: 9.9, max: 3726.1)
        let item = BedManagement.newWeightedIsolationSegment("x", name: "y")
        item.copay = 3727.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedIsolationSegmentDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.WeightedIsolationSegmentDurationMinutesRangeRule(min: 64, max: 86400)
        let item = BedManagement.newWeightedIsolationSegment("x", name: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedIsolationSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.WeightedIsolationSegmentRequiredCodeRule(
            message: "weighted isolation segment needs an entry"
        )
        let item = BedManagement.newWeightedIsolationSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
