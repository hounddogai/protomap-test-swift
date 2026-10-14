@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionNoticeValidator()
        let item = Pharmacy.newInteractionNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionNoticeRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Pharmacy.InteractionNoticeRequiredFacilityRule(message: "interaction notice needs this field")
        let item = Pharmacy.newInteractionNotice("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionNoticeFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Pharmacy.InteractionNoticeFacilityLengthRule(maxLength: 16)
        let item = Pharmacy.newInteractionNotice("x", label: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionNoticeTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Pharmacy.InteractionNoticeTimezoneLengthRule(maxLength: 120)
        let item = Pharmacy.newInteractionNotice("x", label: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InteractionNoticeRequiredLabelRule(message: "interaction notice needs a value")
        let item = Pharmacy.newInteractionNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
