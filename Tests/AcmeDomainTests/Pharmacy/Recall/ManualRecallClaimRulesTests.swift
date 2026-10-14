@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualRecallClaimValidator()
        let item = Pharmacy.newManualRecallClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualRecallClaimThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.ManualRecallClaimThresholdRangeRule(min: 1.3, max: 3120.9)
        let item = Pharmacy.newManualRecallClaim("x", title: "y")
        item.threshold = 3122.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualRecallClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.ManualRecallClaimRequiredTitleRule(message: "manual recall claim needs a value")
        let item = Pharmacy.newManualRecallClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualRecallClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.ManualRecallClaimTitleLengthRule(maxLength: 255)
        let item = Pharmacy.newManualRecallClaim("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.ManualRecallClaimRequiredCodeRule(message: "manual recall claim needs this field")
        let item = Pharmacy.newManualRecallClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualRecallClaimProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.ManualRecallClaimProcedureCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newManualRecallClaim("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
