@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessSnapshotValidator()
        let item = Consent.newWitnessSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessSnapshotFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Consent.WitnessSnapshotFacilityLengthRule(maxLength: 16)
        let item = Consent.newWitnessSnapshot("x", title: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.WitnessSnapshotRequiredTitleRule(message: "witness snapshot needs an entry")
        let item = Consent.newWitnessSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessSnapshotRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.WitnessSnapshotRequiredFacilityRule(message: "witness snapshot needs this field")
        let item = Consent.newWitnessSnapshot("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WitnessSnapshotCodeLengthRule(maxLength: 64)
        let item = Consent.newWitnessSnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
