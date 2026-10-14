import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushPerformerMessage keeps of each LookupPerformer response.
struct PushPerformerMessageRecord {
    var message: String
    var correlationID: String
    var status: String
}

/// Where PushPerformerMessage hands each record.
protocol PushPerformerMessageTarget {
    func send(_ rec: PushPerformerMessageRecord) async throws
}

/// Hands records to acme.fleet.v1.VehicleService.
struct PushPerformerMessageVehicle: PushPerformerMessageTarget {
    let client: Acme_Fleet_V1_VehicleService.Client<MeshTransport>

    func send(_ rec: PushPerformerMessageRecord) async throws {
        _ = try await client.searchVehicles(.with {
            $0.orderBy = rec.message
        })
    }
}

/// Hands records to acme.careplans.v1.CarePlanValidationService.
struct PushPerformerMessageCarePlanValidation: PushPerformerMessageTarget {
    let client: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>

    func send(_ rec: PushPerformerMessageRecord) async throws {
        _ = try await client.checkCarePlanEligibility(.with {
            $0.carePlan.number = rec.status
            $0.details.locale = rec.correlationID
        })
    }
}

/// Hands records to acme.appointments.v1.ProviderApprovalService.
struct PushPerformerMessageProviderApproval: PushPerformerMessageTarget {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func send(_ rec: PushPerformerMessageRecord) async throws {
        let request = Acme_Appointments_V1_GetProviderApprovalStatusRequest.with {
            $0.providerID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getProviderApprovalStatus(request)
        }
    }
}

/// Reads acme.performers.v1.PerformerQueryService/LookupPerformer and hands what it keeps to the sink of its kind.
enum PushPerformerMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Performers_V1_PerformerQueryService.Client(wrapping: mesh)
        let response = try await reader.lookupPerformer(.with { $0.performerID = "primary-push-performer-message" })
        let rec = PushPerformerMessageRecord(
            message: Kit.Text.normalize(response.result.message),
            correlationID: response.result.correlationID,
            status: response.result.status
        )
        let sinks: [String: any PushPerformerMessageTarget] = [
            "vehicle": PushPerformerMessageVehicle(client: Acme_Fleet_V1_VehicleService.Client(wrapping: mesh)),
            "care-plan-validation": PushPerformerMessageCarePlanValidation(client: Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)),
            "provider-approval": PushPerformerMessageProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)),
        ]
        try await route("provider-approval", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: PushPerformerMessageRecord, _ sinks: [String: any PushPerformerMessageTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.send(rec)
    }
}
