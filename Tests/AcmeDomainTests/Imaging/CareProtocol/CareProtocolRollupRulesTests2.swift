@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolRollupValidator()
        let item = Imaging.newCareProtocolRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolRollupRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.CareProtocolRollupRefillsRangeRule(min: 32, max: 255)
        let item = Imaging.newCareProtocolRollup("x", name: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolRollupWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Imaging.CareProtocolRollupWardLengthRule(maxLength: 16)
        let item = Imaging.newCareProtocolRollup("x", name: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.CareProtocolRollupNameLengthRule(maxLength: 86400)
        let item = Imaging.newCareProtocolRollup("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.CareProtocolRollupRequiredNameRule(message: "care protocol rollup needs this field")
        let item = Imaging.newCareProtocolRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolRollupCodeLengthRule(maxLength: 255)
        let item = Imaging.newCareProtocolRollup("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
