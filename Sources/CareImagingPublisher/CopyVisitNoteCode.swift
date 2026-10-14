import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyVisitNoteCode keeps of each ScoreVisitNote response.
struct CopyVisitNoteCodeRecord {
    var currencyCode: String
    var number: String
    var visitNoteID: String
}

/// Where CopyVisitNoteCode hands each record.
protocol CopyVisitNoteCodeSink {
    func deliver(_ rec: CopyVisitNoteCodeRecord) async throws
}

/// Sends records to acme.telehealth.v1.VisitNoteWorkflowService.
struct CopyVisitNoteCodeVisitNoteWorkflow: CopyVisitNoteCodeSink {
    let client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>

    func deliver(_ rec: CopyVisitNoteCodeRecord) async throws {
        let request = Acme_Telehealth_V1_AdvanceVisitNoteWorkflowRequest.with {
            $0.visitNote.number = rec.currencyCode
            $0.visitNoteID = rec.visitNoteID
            $0.details.initiatedBy = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.advanceVisitNoteWorkflow(request)
        }
    }
}

/// Hands records to acme.collections.v1.CollectionCaseService.
struct CopyVisitNoteCodeCollectionCase: CopyVisitNoteCodeSink {
    let client: Acme_Collections_V1_CollectionCaseService.Client<MeshTransport>

    func deliver(_ rec: CopyVisitNoteCodeRecord) async throws {
        let request = Acme_Collections_V1_GetCollectionCaseRequest.with {
            $0.collectionCaseID = rec.currencyCode
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getCollectionCase(request)
        }
    }
}

/// Writes records to acme.fleet.v1.VehicleService.
struct CopyVisitNoteCodeVehicle: CopyVisitNoteCodeSink {
    let client: Acme_Fleet_V1_VehicleService.Client<MeshTransport>

    func deliver(_ rec: CopyVisitNoteCodeRecord) async throws {
        _ = try await client.deleteVehicle(.with {
            $0.reason = rec.visitNoteID
        })
    }
}

/// Reads acme.telehealth.v1.VisitNoteValidationService/ScoreVisitNote and hands what it keeps to the sink of its kind.
enum CopyVisitNoteCode {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)
        let found = try await reader.scoreVisitNote(.with { $0.visitNoteID = "nightly-copy-visit-note-code" })
        let row = CopyVisitNoteCodeRecord(
            currencyCode: found.breakdown.currencyCode,
            number: found.visitNote.number,
            visitNoteID: found.visitNote.visitNoteID
        )
        let sinks: [any CopyVisitNoteCodeSink] = [
            CopyVisitNoteCodeVisitNoteWorkflow(client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh)),
            CopyVisitNoteCodeCollectionCase(client: Acme_Collections_V1_CollectionCaseService.Client(wrapping: mesh)),
            CopyVisitNoteCodeVehicle(client: Acme_Fleet_V1_VehicleService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.deliver(row)
        }
    }
}
