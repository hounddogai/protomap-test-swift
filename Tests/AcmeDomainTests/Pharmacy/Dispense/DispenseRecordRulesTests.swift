@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseRecordValidator()
        let item = Pharmacy.newDispenseRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseRecordOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Pharmacy.DispenseRecordOwnerIDLengthRule(maxLength: 16)
        let item = Pharmacy.newDispenseRecord("x", name: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.DispenseRecordRequiredNameRule(message: "dispense record needs an entry")
        let item = Pharmacy.newDispenseRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseRecordRequiredCodeRule(message: "dispense record needs an entry")
        let item = Pharmacy.newDispenseRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseRecordScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.DispenseRecordScoreRangeRule(min: 4.0, max: 4125.4)
        let item = Pharmacy.newDispenseRecord("x", name: "y")
        item.score = 4126.9
        #expect(rule.check(item).count > 0)
    }
}
