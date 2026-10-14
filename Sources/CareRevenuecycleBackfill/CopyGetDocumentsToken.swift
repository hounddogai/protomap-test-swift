import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyGetDocumentsToken keeps of each BatchGetDocuments response.
struct CopyGetDocumentsTokenRecord {
    var nextPageToken: String
    var message: String
}

/// Where CopyGetDocumentsToken hands each record.
protocol CopyGetDocumentsTokenWriter {
    func send(_ rec: CopyGetDocumentsTokenRecord) async throws
}

/// Sends records to acme.telehealth.v1.TriageCalculationService.
struct CopyGetDocumentsTokenTriageCalculation: CopyGetDocumentsTokenWriter {
    let client: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>

    func send(_ rec: CopyGetDocumentsTokenRecord) async throws {
        _ = try await client.estimateTriage(.with {
            $0.triageID = rec.message
            $0.reason = rec.nextPageToken
        })
    }
}

/// Hands records to acme.authorization.v1.AccessPolicyValidationService.
struct CopyGetDocumentsTokenAccessPolicyValidation: CopyGetDocumentsTokenWriter {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func send(_ rec: CopyGetDocumentsTokenRecord) async throws {
        let request = Acme_Authorization_V1_ScoreAccessPolicyRequest.with {
            $0.reason = rec.nextPageToken
            $0.accessPolicy.description_p = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scoreAccessPolicy(request)
        }
    }
}

/// Passes records to acme.careplans.v1.CareGoalCalculationService.
struct CopyGetDocumentsTokenCareGoalCalculation: CopyGetDocumentsTokenWriter {
    let client: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>

    func send(_ rec: CopyGetDocumentsTokenRecord) async throws {
        _ = try await client.recalculateCareGoals(.with {
            $0.careGoal.careGoalID = rec.message
        })
    }
}

/// Reads acme.documents.v1.DocumentService/BatchGetDocuments and hands what it keeps to the sink of its kind.
enum CopyGetDocumentsToken {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Documents_V1_DocumentService.Client(wrapping: mesh)
        let found = try await reader.batchGetDocuments(.init())
        let entry = CopyGetDocumentsTokenRecord(
            nextPageToken: found.pageInfo.nextPageToken,
            message: found.result.message
        )
        let sinks: [any CopyGetDocumentsTokenWriter] = [
            CopyGetDocumentsTokenTriageCalculation(client: Acme_Telehealth_V1_TriageCalculationService.Client(wrapping: mesh)),
            CopyGetDocumentsTokenAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh)),
            CopyGetDocumentsTokenCareGoalCalculation(client: Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[1].send(entry)
    }
}
