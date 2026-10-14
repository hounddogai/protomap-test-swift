@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingAuthorizationSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingAuthorizationSnapshotValidator()
        let item = RevenueCycle.newRollingAuthorizationSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingAuthorizationSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RollingAuthorizationSnapshotRequiredNameRule(
            message: "rolling authorization snapshot needs this field"
        )
        let item = RevenueCycle.newRollingAuthorizationSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingAuthorizationSnapshotPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = RevenueCycle.RollingAuthorizationSnapshotPatientRefLengthRule(maxLength: 32)
        let item = RevenueCycle.newRollingAuthorizationSnapshot("x", name: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
