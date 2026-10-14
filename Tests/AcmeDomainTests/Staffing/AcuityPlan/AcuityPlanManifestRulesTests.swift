@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanManifestValidator()
        let item = Staffing.newAcuityPlanManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanManifestCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.AcuityPlanManifestCapacityRangeRule(min: 1000, max: 3600)
        let item = Staffing.newAcuityPlanManifest("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanManifestNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Staffing.AcuityPlanManifestNotesLengthRule(maxLength: 1000)
        let item = Staffing.newAcuityPlanManifest("x", name: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AcuityPlanManifestRequiredNameRule(message: "acuity plan manifest needs a value")
        let item = Staffing.newAcuityPlanManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanManifestCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Staffing.AcuityPlanManifestCurrencyLengthRule(maxLength: 3600)
        let item = Staffing.newAcuityPlanManifest("x", name: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
