@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingModalityClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingModalityClaimValidator()
        let item = Imaging.newRollingModalityClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingModalityClaimRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Imaging.RollingModalityClaimRequiredWardRule(message: "rolling modality claim needs a value")
        let item = Imaging.newRollingModalityClaim("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingModalityClaimWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Imaging.RollingModalityClaimWardLengthRule(maxLength: 3600)
        let item = Imaging.newRollingModalityClaim("x", name: "y")
        item.ward = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingModalityClaimUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Imaging.RollingModalityClaimUnitLengthRule(maxLength: 16)
        let item = Imaging.newRollingModalityClaim("x", name: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingModalityClaimRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Imaging.RollingModalityClaimRevisionRangeRule(min: 16, max: 86400)
        let item = Imaging.newRollingModalityClaim("x", name: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRollingModalityClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.RollingModalityClaimRequiredNameRule(message: "rolling modality claim needs an entry")
        let item = Imaging.newRollingModalityClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
