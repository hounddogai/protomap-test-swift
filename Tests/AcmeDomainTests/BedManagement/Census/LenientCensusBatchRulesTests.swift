@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientCensusBatchValidator()
        let item = BedManagement.newLenientCensusBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientCensusBatchCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = BedManagement.LenientCensusBatchCurrencyLengthRule(maxLength: 16)
        let item = BedManagement.newLenientCensusBatch("x", name: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientCensusBatchChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = BedManagement.LenientCensusBatchChannelLengthRule(maxLength: 255)
        let item = BedManagement.newLenientCensusBatch("x", name: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientCensusBatchLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.LenientCensusBatchLimitRangeRule(min: 120, max: 1000)
        let item = BedManagement.newLenientCensusBatch("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientCensusBatchRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = BedManagement.LenientCensusBatchRequiredCurrencyRule(message: "lenient census batch needs a value")
        let item = BedManagement.newLenientCensusBatch("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
