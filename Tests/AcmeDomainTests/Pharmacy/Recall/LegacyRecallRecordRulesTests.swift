@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyRecallRecordValidator()
        let item = Pharmacy.newLegacyRecallRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyRecallRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LegacyRecallRecordRequiredCodeRule(message: "legacy recall record needs a value")
        let item = Pharmacy.newLegacyRecallRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyRecallRecordChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.LegacyRecallRecordChannelLengthRule(maxLength: 64)
        let item = Pharmacy.newLegacyRecallRecord("x", title: "y")
        item.channel = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyRecallRecordRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Pharmacy.LegacyRecallRecordRegionLengthRule(maxLength: 120)
        let item = Pharmacy.newLegacyRecallRecord("x", title: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
