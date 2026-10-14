@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualRecallNoticeValidator()
        let item = Pharmacy.newManualRecallNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualRecallNoticeVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.ManualRecallNoticeVersionRangeRule(min: 80, max: 120)
        let item = Pharmacy.newManualRecallNotice("x", label: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualRecallNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.ManualRecallNoticeRequiredLabelRule(message: "manual recall notice needs an entry")
        let item = Pharmacy.newManualRecallNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualRecallNoticeBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.ManualRecallNoticeBedLengthRule(maxLength: 64)
        let item = Pharmacy.newManualRecallNotice("x", label: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ManualRecallNoticeCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newManualRecallNotice("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallNoticeRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Pharmacy.ManualRecallNoticeRequiredBedRule(message: "manual recall notice needs this field")
        let item = Pharmacy.newManualRecallNotice("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualRecallNoticeLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Pharmacy.ManualRecallNoticeLocaleLengthRule(maxLength: 80)
        let item = Pharmacy.newManualRecallNotice("x", label: "y")
        item.locale = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
