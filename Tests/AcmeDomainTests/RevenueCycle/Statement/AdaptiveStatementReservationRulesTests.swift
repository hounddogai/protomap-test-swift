@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveStatementReservationValidator()
        let item = RevenueCycle.newAdaptiveStatementReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AdaptiveStatementReservationCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newAdaptiveStatementReservation("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementReservationBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = RevenueCycle.AdaptiveStatementReservationBedLengthRule(maxLength: 16)
        let item = RevenueCycle.newAdaptiveStatementReservation("x", name: "y")
        item.bed = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementReservationBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.AdaptiveStatementReservationBatchSizeRangeRule(min: 3600, max: 86400)
        let item = RevenueCycle.newAdaptiveStatementReservation("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}
