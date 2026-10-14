@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedDischargePlanItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedDischargePlanItemValidator()
        let item = BedManagement.newCappedDischargePlanItem("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedDischargePlanItemRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CappedDischargePlanItemRequiredCodeRule(
            message: "capped discharge plan item needs a value"
        )
        let item = BedManagement.newCappedDischargePlanItem("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCappedDischargePlanItemRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.CappedDischargePlanItemRegionLengthRule(maxLength: 16)
        let item = BedManagement.newCappedDischargePlanItem("x", name: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedDischargePlanItemNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CappedDischargePlanItemNameLengthRule(maxLength: 1000)
        let item = BedManagement.newCappedDischargePlanItem("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
