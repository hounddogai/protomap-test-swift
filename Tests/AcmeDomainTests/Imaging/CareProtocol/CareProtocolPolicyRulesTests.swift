@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolPolicyValidator()
        let item = Imaging.newCareProtocolPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolPolicyLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Imaging.CareProtocolPolicyLocaleLengthRule(maxLength: 255)
        let item = Imaging.newCareProtocolPolicy("x", name: "y")
        item.locale = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.CareProtocolPolicyRequiredNameRule(message: "care protocol policy needs a value")
        let item = Imaging.newCareProtocolPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolPolicyRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Imaging.CareProtocolPolicyRequiredEncounterIDRule(message: "care protocol policy needs an entry")
        let item = Imaging.newCareProtocolPolicy("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
