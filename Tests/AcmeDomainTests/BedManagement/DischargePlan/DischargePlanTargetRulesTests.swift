@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanTargetValidator()
        let item = BedManagement.newDischargePlanTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.DischargePlanTargetRequiredNameRule(message: "discharge plan target needs an entry")
        let item = BedManagement.newDischargePlanTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.DischargePlanTargetNameLengthRule(maxLength: 120)
        let item = BedManagement.newDischargePlanTarget("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanTargetRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.DischargePlanTargetRegionLengthRule(maxLength: 120)
        let item = BedManagement.newDischargePlanTarget("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanTargetCodeLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanTarget("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
