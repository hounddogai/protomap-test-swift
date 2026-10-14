import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateVehiclesToken keeps of each SearchVehicles response.
struct PropagateVehiclesTokenRecord {
    var nextPageToken: String
    var status: String
}

/// Where PropagateVehiclesToken hands each record.
protocol PropagateVehiclesTokenDestination {
    func send(_ rec: PropagateVehiclesTokenRecord) async throws
}

/// Passes records to acme.patients.v1.AllergyWorkflowService.
struct PropagateVehiclesTokenAllergyWorkflow: PropagateVehiclesTokenDestination {
    let client: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>

    func send(_ rec: PropagateVehiclesTokenRecord) async throws {
        _ = try await client.startAllergyWorkflow(.with {
            $0.reason = rec.status
        })
    }
}

/// Hands records to acme.shows.v1.ShowCalculationService.
struct PropagateVehiclesTokenShowCalculation: PropagateVehiclesTokenDestination {
    let client: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>

    func send(_ rec: PropagateVehiclesTokenRecord) async throws {
        let request = Acme_Shows_V1_RecalculateShowsRequest.with {
            $0.showID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.recalculateShows(request)
        }
    }
}

/// Hands records to acme.careplans.v1.CareGoalCalculationService.
struct PropagateVehiclesTokenCareGoalCalculation: PropagateVehiclesTokenDestination {
    let client: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>

    func send(_ rec: PropagateVehiclesTokenRecord) async throws {
        _ = try await client.simulateCareGoal(.with {
            $0.careGoal.subject = rec.nextPageToken
            $0.details.currencyCode = rec.status
        })
    }
}

/// Reads acme.fleet.v1.VehicleService/SearchVehicles and hands what it keeps to the sink of its kind.
enum PropagateVehiclesToken {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Fleet_V1_VehicleService.Client(wrapping: mesh)
        let reply = try await origin.searchVehicles(.with { $0.orderBy = "nightly-propagate-vehicles-token" })
        let row = PropagateVehiclesTokenRecord(
            nextPageToken: Kit.Text.normalize(reply.pageInfo.nextPageToken),
            status: reply.result.status
        )
        try await act("show-calculation", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: PropagateVehiclesTokenRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "allergy-workflow": { try await PropagateVehiclesTokenAllergyWorkflow(client: Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)).send(rec) },
            "show-calculation": { try await PropagateVehiclesTokenShowCalculation(client: Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh)).send(rec) },
            "care-goal-calculation": { try await PropagateVehiclesTokenCareGoalCalculation(client: Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)).send(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
