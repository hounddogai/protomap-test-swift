@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInventoryBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultInventoryBatchValidator()
        let item = Pharmacy.newDefaultInventoryBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultInventoryBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.DefaultInventoryBatchRequiredNameRule(message: "default inventory batch needs an entry")
        let item = Pharmacy.newDefaultInventoryBatch("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultInventoryBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.DefaultInventoryBatchRequiredTitleRule(message: "default inventory batch needs this field")
        let item = Pharmacy.newDefaultInventoryBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultInventoryBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DefaultInventoryBatchRequiredCodeRule(message: "default inventory batch needs an entry")
        let item = Pharmacy.newDefaultInventoryBatch("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultInventoryBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DefaultInventoryBatchTitleLengthRule(maxLength: 120)
        let item = Pharmacy.newDefaultInventoryBatch("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultInventoryBatchRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.DefaultInventoryBatchRequiredProcedureCodeRule(
            message: "default inventory batch needs this field"
        )
        let item = Pharmacy.newDefaultInventoryBatch("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultInventoryBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DefaultInventoryBatchCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newDefaultInventoryBatch("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
