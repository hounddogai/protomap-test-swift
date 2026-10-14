import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateRefillOptionsMessage keeps of each CompareRefillOptions response.
struct PropagateRefillOptionsMessageRecord {
    var message: String
    var correlationID: String
}

/// Where PropagateRefillOptionsMessage hands each record.
protocol PropagateRefillOptionsMessageTarget {
    func send(_ rec: PropagateRefillOptionsMessageRecord) async throws
}

/// Hands records to acme.careplans.v1.CarePlanCalculationService.
struct PropagateRefillOptionsMessageCarePlanCalculation: PropagateRefillOptionsMessageTarget {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func send(_ rec: PropagateRefillOptionsMessageRecord) async throws {
        _ = try await client.compareCarePlanOptions(.with {
            $0.carePlan.number = rec.correlationID
            $0.reason = rec.message
        })
    }
}

/// Sends records to acme.appointments.v1.ProviderApprovalService.
struct PropagateRefillOptionsMessageProviderApproval: PropagateRefillOptionsMessageTarget {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func send(_ rec: PropagateRefillOptionsMessageRecord) async throws {
        _ = try await client.recallProvider(.with {
            $0.providerID = rec.message
            $0.provider.providerID = rec.correlationID
        })
    }
}

/// Reads acme.prescriptions.v1.RefillCalculationService/CompareRefillOptions and hands what it keeps to the sink of its kind.
enum PropagateRefillOptionsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh)
        let response = try await reader.compareRefillOptions(.with { $0.reason = "primary-propagate-refill-options-message" })
        let record = PropagateRefillOptionsMessageRecord(
            message: Kit.Text.normalize(response.result.message),
            correlationID: response.result.correlationID
        )
        let sinks: [any PropagateRefillOptionsMessageTarget] = [
            PropagateRefillOptionsMessageCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh)),
            PropagateRefillOptionsMessageProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)),
        ]
        try await sinks[1].send(record)
    }
}
