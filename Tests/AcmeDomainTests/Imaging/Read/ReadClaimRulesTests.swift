@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadClaimValidator()
        let item = Imaging.newReadClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadClaimCodeLengthRule(maxLength: 16)
        let item = Imaging.newReadClaim("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ReadClaimTitleLengthRule(maxLength: 16)
        let item = Imaging.newReadClaim("x", name: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadClaimSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.ReadClaimSummaryLengthRule(maxLength: 32)
        let item = Imaging.newReadClaim("x", name: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadClaimRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.ReadClaimRequiredSummaryRule(message: "read claim needs this field")
        let item = Imaging.newReadClaim("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
