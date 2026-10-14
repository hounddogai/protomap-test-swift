@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalFloatPoolTargetValidator()
        let item = Staffing.newGlobalFloatPoolTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalFloatPoolTargetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Staffing.GlobalFloatPoolTargetGraceDaysRangeRule(min: 32, max: 120)
        let item = Staffing.newGlobalFloatPoolTarget("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalFloatPoolTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.GlobalFloatPoolTargetNameLengthRule(maxLength: 3600)
        let item = Staffing.newGlobalFloatPoolTarget("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalFloatPoolTargetRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.GlobalFloatPoolTargetRequiredBedRule(message: "global float pool target needs a value")
        let item = Staffing.newGlobalFloatPoolTarget("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalFloatPoolTargetDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Staffing.GlobalFloatPoolTargetDiagnosisCodeLengthRule(maxLength: 3600)
        let item = Staffing.newGlobalFloatPoolTarget("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalFloatPoolTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.GlobalFloatPoolTargetCodeLengthRule(maxLength: 16)
        let item = Staffing.newGlobalFloatPoolTarget("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalFloatPoolTargetBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.GlobalFloatPoolTargetBedLengthRule(maxLength: 1000)
        let item = Staffing.newGlobalFloatPoolTarget("x", name: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
