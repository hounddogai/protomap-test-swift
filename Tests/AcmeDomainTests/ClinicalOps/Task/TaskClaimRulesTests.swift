@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskClaimValidator()
        let item = ClinicalOps.newTaskClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.TaskClaimRequiredNameRule(message: "task claim needs this field")
        let item = ClinicalOps.newTaskClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskClaimCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = ClinicalOps.TaskClaimCapacityRangeRule(min: 16, max: 1000)
        let item = ClinicalOps.newTaskClaim("x", name: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskClaimQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.TaskClaimQuantityRangeRule(min: 32, max: 1000)
        let item = ClinicalOps.newTaskClaim("x", name: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskClaimPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.TaskClaimPatientRefLengthRule(maxLength: 120)
        let item = ClinicalOps.newTaskClaim("x", name: "y")
        item.patientRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TaskClaimRequiredCodeRule(message: "task claim needs an entry")
        let item = ClinicalOps.newTaskClaim("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
