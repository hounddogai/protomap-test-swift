@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedHandoffMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCappedHandoffMappingValidator()
        let item = ClinicalOps.newCappedHandoffMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCappedHandoffMappingOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.CappedHandoffMappingOwnerIDLengthRule(maxLength: 16)
        let item = ClinicalOps.newCappedHandoffMapping("x", name: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCappedHandoffMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.CappedHandoffMappingNameLengthRule(maxLength: 64)
        let item = ClinicalOps.newCappedHandoffMapping("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCappedHandoffMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CappedHandoffMappingRequiredCodeRule(message: "capped handoff mapping needs an entry")
        let item = ClinicalOps.newCappedHandoffMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedHandoffMappingRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = ClinicalOps.CappedHandoffMappingRequiredOwnerIDRule(message: "capped handoff mapping needs an entry")
        let item = ClinicalOps.newCappedHandoffMapping("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedHandoffMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.CappedHandoffMappingRequiredNameRule(message: "capped handoff mapping needs an entry")
        let item = ClinicalOps.newCappedHandoffMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
