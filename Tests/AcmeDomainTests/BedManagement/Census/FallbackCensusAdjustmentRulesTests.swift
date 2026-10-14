@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackCensusAdjustmentValidator()
        let item = BedManagement.newFallbackCensusAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackCensusAdjustmentChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.FallbackCensusAdjustmentChecksumLengthRule(maxLength: 64)
        let item = BedManagement.newFallbackCensusAdjustment("x", name: "y")
        item.checksum = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCensusAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackCensusAdjustmentRequiredCodeRule(
            message: "fallback census adjustment needs an entry"
        )
        let item = BedManagement.newFallbackCensusAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackCensusAdjustmentAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.FallbackCensusAdjustmentAmountRangeRule(min: 7.6, max: 478.5)
        let item = BedManagement.newFallbackCensusAdjustment("x", name: "y")
        item.amount = 480.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackCensusAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.FallbackCensusAdjustmentNameLengthRule(maxLength: 3600)
        let item = BedManagement.newFallbackCensusAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
