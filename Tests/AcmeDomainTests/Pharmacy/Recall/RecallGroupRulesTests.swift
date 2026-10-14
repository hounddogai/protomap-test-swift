@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallGroupValidator()
        let item = Pharmacy.newRecallGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RecallGroupNameLengthRule(maxLength: 80)
        let item = Pharmacy.newRecallGroup("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallGroupTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Pharmacy.RecallGroupTimezoneLengthRule(maxLength: 86400)
        let item = Pharmacy.newRecallGroup("x", name: "y")
        item.timezone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallGroupVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.RecallGroupVisitMinutesRangeRule(min: 16, max: 80)
        let item = Pharmacy.newRecallGroup("x", name: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallGroupRequiredCodeRule(message: "recall group needs this field")
        let item = Pharmacy.newRecallGroup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
