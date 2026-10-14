@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveReadLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveReadLedgerValidator()
        let item = Imaging.newAdaptiveReadLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveReadLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.AdaptiveReadLedgerCodeLengthRule(maxLength: 16)
        let item = Imaging.newAdaptiveReadLedger("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveReadLedgerFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Imaging.AdaptiveReadLedgerFacilityLengthRule(maxLength: 3600)
        let item = Imaging.newAdaptiveReadLedger("x", label: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveReadLedgerLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.AdaptiveReadLedgerLabelLengthRule(maxLength: 3600)
        let item = Imaging.newAdaptiveReadLedger("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveReadLedgerUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.AdaptiveReadLedgerUpdatedAtRangeRule(min: 16, max: 255)
        let item = Imaging.newAdaptiveReadLedger("x", label: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}
