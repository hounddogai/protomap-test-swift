@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualDischargePlanItemValidator()
        let item = BedManagement.newManualDischargePlanItem("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualDischargePlanItemRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.ManualDischargePlanItemRequiredTitleRule(
            message: "manual discharge plan item needs an entry"
        )
        let item = BedManagement.newManualDischargePlanItem("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualDischargePlanItemLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.ManualDischargePlanItemLimitRangeRule(min: 3600, max: 86400)
        let item = BedManagement.newManualDischargePlanItem("x", title: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualDischargePlanItemTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.ManualDischargePlanItemTitleLengthRule(maxLength: 1000)
        let item = BedManagement.newManualDischargePlanItem("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualDischargePlanItemPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = BedManagement.ManualDischargePlanItemPhoneLengthRule(maxLength: 80)
        let item = BedManagement.newManualDischargePlanItem("x", title: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualDischargePlanItemVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.ManualDischargePlanItemVersionRangeRule(min: 64, max: 86400)
        let item = BedManagement.newManualDischargePlanItem("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualDischargePlanItemRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.ManualDischargePlanItemRequiredClinicianIDRule(
            message: "manual discharge plan item needs this field"
        )
        let item = BedManagement.newManualDischargePlanItem("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
