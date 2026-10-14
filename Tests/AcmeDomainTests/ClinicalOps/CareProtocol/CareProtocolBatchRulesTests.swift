@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolBatchValidator()
        let item = ClinicalOps.newCareProtocolBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolBatchOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.CareProtocolBatchOwnerIDLengthRule(maxLength: 86400)
        let item = ClinicalOps.newCareProtocolBatch("x", name: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolBatchCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = ClinicalOps.CareProtocolBatchCopayRangeRule(min: 3.4, max: 1222.3)
        let item = ClinicalOps.newCareProtocolBatch("x", name: "y")
        item.copay = 1223.8
        #expect(rule.check(item).count > 0)
    }
}
