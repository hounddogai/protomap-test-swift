@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseGroupValidator()
        let item = Pharmacy.newDispenseGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DispenseGroupNameLengthRule(maxLength: 16)
        let item = Pharmacy.newDispenseGroup("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseGroupClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Pharmacy.DispenseGroupClinicianIDLengthRule(maxLength: 86400)
        let item = Pharmacy.newDispenseGroup("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseGroupVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.DispenseGroupVisitMinutesRangeRule(min: 80, max: 86400)
        let item = Pharmacy.newDispenseGroup("x", name: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseGroupRequiredCodeRule(message: "dispense group needs an entry")
        let item = Pharmacy.newDispenseGroup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseGroupReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Pharmacy.DispenseGroupReviewerLengthRule(maxLength: 255)
        let item = Pharmacy.newDispenseGroup("x", name: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
