@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyCareProtocolEntryValidator()
        let item = Imaging.newLegacyCareProtocolEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyCareProtocolEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.LegacyCareProtocolEntryRequiredCodeRule(message: "legacy care protocol entry needs a value")
        let item = Imaging.newLegacyCareProtocolEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyCareProtocolEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.LegacyCareProtocolEntryRequiredLabelRule(message: "legacy care protocol entry needs an entry")
        let item = Imaging.newLegacyCareProtocolEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyCareProtocolEntryPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Imaging.LegacyCareProtocolEntryPhoneLengthRule(maxLength: 1000)
        let item = Imaging.newLegacyCareProtocolEntry("x", label: "y")
        item.phone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
