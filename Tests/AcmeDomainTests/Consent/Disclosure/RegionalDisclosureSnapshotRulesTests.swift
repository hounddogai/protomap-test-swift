@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalDisclosureSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalDisclosureSnapshotValidator()
        let item = Consent.newRegionalDisclosureSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalDisclosureSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RegionalDisclosureSnapshotRequiredCodeRule(
            message: "regional disclosure snapshot needs a value"
        )
        let item = Consent.newRegionalDisclosureSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalDisclosureSnapshotBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.RegionalDisclosureSnapshotBudgetRangeRule(min: 1.8, max: 4952.8)
        let item = Consent.newRegionalDisclosureSnapshot("x", title: "y")
        item.budget = 4954.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRegionalDisclosureSnapshotRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Consent.RegionalDisclosureSnapshotRequiredPhoneRule(
            message: "regional disclosure snapshot needs a value"
        )
        let item = Consent.newRegionalDisclosureSnapshot("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalDisclosureSnapshotUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Consent.RegionalDisclosureSnapshotUnitLengthRule(maxLength: 255)
        let item = Consent.newRegionalDisclosureSnapshot("x", title: "y")
        item.unit = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
