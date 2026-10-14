import AcmeContracts
import AcmePlatform
import Foundation
import SwiftProtobuf

/// The stored representation of a care goal.
struct CareGoalRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Careplans_V1_CareGoal, tenant: String) throws {
        self.identifier = message.careGoalID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "care_goal", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Careplans_V1_CareGoal {
        try Acme_Careplans_V1_CareGoal(serializedBytes: payload)
    }
}

/// The stored representation of a care plan.
struct CarePlanRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Careplans_V1_CarePlan, tenant: String) throws {
        self.identifier = message.carePlanID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "care_plan", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Careplans_V1_CarePlan {
        try Acme_Careplans_V1_CarePlan(serializedBytes: payload)
    }
}

/// The stored representation of a vital.
struct VitalRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Careplans_V1_Vital, tenant: String) throws {
        self.identifier = message.vitalID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "vital", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Careplans_V1_Vital {
        try Acme_Careplans_V1_Vital(serializedBytes: payload)
    }
}
