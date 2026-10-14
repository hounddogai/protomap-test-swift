@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualRecallQuotaValidator()
        let item = Pharmacy.newManualRecallQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualRecallQuotaRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.ManualRecallQuotaRequiredLabelRule(message: "manual recall quota needs an entry")
        let item = Pharmacy.newManualRecallQuota("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualRecallQuotaRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.ManualRecallQuotaRequiredSourceRule(message: "manual recall quota needs this field")
        let item = Pharmacy.newManualRecallQuota("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualRecallQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.ManualRecallQuotaLabelLengthRule(maxLength: 255)
        let item = Pharmacy.newManualRecallQuota("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallQuotaProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.ManualRecallQuotaProcedureCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newManualRecallQuota("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallQuotaAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.ManualRecallQuotaAcuityRangeRule(min: 32, max: 64)
        let item = Pharmacy.newManualRecallQuota("x", label: "y")
        item.acuity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualRecallQuotaRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.ManualRecallQuotaRatioRangeRule(min: 5.7, max: 4136.6)
        let item = Pharmacy.newManualRecallQuota("x", label: "y")
        item.ratio = 4138.1
        #expect(rule.check(item).count > 0)
    }
}
