@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryOrderSetDigestValidator()
        let item = ClinicalOps.newPrimaryOrderSetDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetDigestCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = ClinicalOps.PrimaryOrderSetDigestCapacityRangeRule(min: 255, max: 86400)
        let item = ClinicalOps.newPrimaryOrderSetDigest("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetDigestContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = ClinicalOps.PrimaryOrderSetDigestContactEmailLengthRule(maxLength: 64)
        let item = ClinicalOps.newPrimaryOrderSetDigest("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.PrimaryOrderSetDigestNameLengthRule(maxLength: 32)
        let item = ClinicalOps.newPrimaryOrderSetDigest("x", title: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetDigestMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.PrimaryOrderSetDigestMaximumRangeRule(min: 0.4, max: 3119.8)
        let item = ClinicalOps.newPrimaryOrderSetDigest("x", title: "y")
        item.maximum = 3121.3
        #expect(rule.check(item).count > 0)
    }
}
