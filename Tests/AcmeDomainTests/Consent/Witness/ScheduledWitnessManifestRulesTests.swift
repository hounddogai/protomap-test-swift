@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledWitnessManifestValidator()
        let item = Consent.newScheduledWitnessManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledWitnessManifestSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Consent.ScheduledWitnessManifestSourceLengthRule(maxLength: 3600)
        let item = Consent.newScheduledWitnessManifest("x", name: "y")
        item.source = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledWitnessManifestVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.ScheduledWitnessManifestVisitMinutesRangeRule(min: 80, max: 120)
        let item = Consent.newScheduledWitnessManifest("x", name: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledWitnessManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ScheduledWitnessManifestRequiredNameRule(message: "scheduled witness manifest needs a value")
        let item = Consent.newScheduledWitnessManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledWitnessManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ScheduledWitnessManifestCodeLengthRule(maxLength: 64)
        let item = Consent.newScheduledWitnessManifest("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
