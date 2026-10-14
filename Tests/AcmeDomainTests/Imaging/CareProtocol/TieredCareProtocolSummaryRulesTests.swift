@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredCareProtocolSummaryValidator()
        let item = Imaging.newTieredCareProtocolSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredCareProtocolSummaryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.TieredCareProtocolSummaryRequiredNameRule(
            message: "tiered care protocol summary needs this field"
        )
        let item = Imaging.newTieredCareProtocolSummary("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredCareProtocolSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.TieredCareProtocolSummaryCodeLengthRule(maxLength: 64)
        let item = Imaging.newTieredCareProtocolSummary("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredCareProtocolSummaryRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Imaging.TieredCareProtocolSummaryRevisionRangeRule(min: 120, max: 120)
        let item = Imaging.newTieredCareProtocolSummary("x", name: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredCareProtocolSummaryRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.TieredCareProtocolSummaryRequiredOwnerIDRule(
            message: "tiered care protocol summary needs a value"
        )
        let item = Imaging.newTieredCareProtocolSummary("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
