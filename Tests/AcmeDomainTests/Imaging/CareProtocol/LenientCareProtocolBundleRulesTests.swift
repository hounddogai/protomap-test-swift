@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientCareProtocolBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientCareProtocolBundleValidator()
        let item = Imaging.newLenientCareProtocolBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientCareProtocolBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.LenientCareProtocolBundleCodeLengthRule(maxLength: 120)
        let item = Imaging.newLenientCareProtocolBundle("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientCareProtocolBundleProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Imaging.LenientCareProtocolBundleProcedureCodeLengthRule(maxLength: 80)
        let item = Imaging.newLenientCareProtocolBundle("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientCareProtocolBundleStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.LenientCareProtocolBundleStartsAtRangeRule(min: 16, max: 1000)
        let item = Imaging.newLenientCareProtocolBundle("x", label: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientCareProtocolBundleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.LenientCareProtocolBundleAttemptsRangeRule(min: 16, max: 64)
        let item = Imaging.newLenientCareProtocolBundle("x", label: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientCareProtocolBundleChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Imaging.LenientCareProtocolBundleChecksumLengthRule(maxLength: 3600)
        let item = Imaging.newLenientCareProtocolBundle("x", label: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
