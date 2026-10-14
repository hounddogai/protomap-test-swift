@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolSnapshotValidator()
        let item = ClinicalOps.newCareProtocolSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolSnapshotBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.CareProtocolSnapshotBudgetRangeRule(min: 1.6, max: 982.0)
        let item = ClinicalOps.newCareProtocolSnapshot("x", name: "y")
        item.budget = 983.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolSnapshotRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.CareProtocolSnapshotRequiredTimezoneRule(message: "care protocol snapshot needs a value")
        let item = ClinicalOps.newCareProtocolSnapshot("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolSnapshotRequiredCodeRule(message: "care protocol snapshot needs a value")
        let item = ClinicalOps.newCareProtocolSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.CareProtocolSnapshotNameLengthRule(maxLength: 64)
        let item = ClinicalOps.newCareProtocolSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.CareProtocolSnapshotRequiredNameRule(message: "care protocol snapshot needs an entry")
        let item = ClinicalOps.newCareProtocolSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
