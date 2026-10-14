import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayFeatureFlagID keeps of each LookupFeatureFlag response.
struct RelayFeatureFlagIDRecord {
    var correlationID: String
    var name: String
    var status: String
    var description: String
}

/// Where RelayFeatureFlagID hands each record.
protocol RelayFeatureFlagIDSink {
    func forward(_ rec: RelayFeatureFlagIDRecord) async throws
}

/// Writes records to acme.appointments.v1.ClinicSlotCalculationService.
struct RelayFeatureFlagIDClinicSlotCalculation: RelayFeatureFlagIDSink {
    let client: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>

    func forward(_ rec: RelayFeatureFlagIDRecord) async throws {
        _ = try await client.estimateClinicSlot(.with {
            $0.clinicSlot.title = rec.status
            $0.clinicSlot.clinicSlotID = rec.correlationID
        })
    }
}

/// Passes records to acme.prescriptions.v1.RefillWorkflowService.
struct RelayFeatureFlagIDRefillWorkflow: RelayFeatureFlagIDSink {
    let client: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>

    func forward(_ rec: RelayFeatureFlagIDRecord) async throws {
        _ = try await client.advanceRefillWorkflow(.with {
            $0.details.initiatedBy = rec.correlationID
            $0.details.step = rec.name
        })
    }
}

/// Reads acme.featureflags.v1.FeatureFlagQueryService/LookupFeatureFlag and hands what it keeps to the sink of its kind.
enum RelayFeatureFlagID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Featureflags_V1_FeatureFlagQueryService.Client(wrapping: mesh)
        let reply = try await reader.lookupFeatureFlag(.with { $0.featureFlagID = "main-relay-feature-flag-id" })
        let row = RelayFeatureFlagIDRecord(
            correlationID: reply.result.correlationID,
            name: reply.featureFlag.name,
            status: reply.result.status,
            description: reply.featureFlag.description_p
        )
        let sinks: [String: any RelayFeatureFlagIDSink] = [
            "clinic-slot-calculation": RelayFeatureFlagIDClinicSlotCalculation(client: Acme_Appointments_V1_ClinicSlotCalculationService.Client(wrapping: mesh)),
            "refill-workflow": RelayFeatureFlagIDRefillWorkflow(client: Acme_Prescriptions_V1_RefillWorkflowService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "clinic-slot-calculation" {
                continue
            }
            try await sink.forward(row)
        }
    }
}
