import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorBroadcastsID keeps of each SummarizeBroadcasts response.
struct MirrorBroadcastsIDRecord {
    var correlationID: String
    var reportID: String
    var status: String
}

/// Where MirrorBroadcastsID hands each record.
protocol MirrorBroadcastsIDSink {
    func send(_ rec: MirrorBroadcastsIDRecord) async throws
}

/// Writes records to acme.careplans.v1.VitalApprovalService.
struct MirrorBroadcastsIDVitalApproval: MirrorBroadcastsIDSink {
    let client: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>

    func send(_ rec: MirrorBroadcastsIDRecord) async throws {
        _ = try await client.getVitalApprovalStatus(.with {
            $0.vitalID = rec.correlationID
        })
    }
}

/// Writes records to acme.shows.v1.ShowQueryService.
struct MirrorBroadcastsIDShowQuery: MirrorBroadcastsIDSink {
    let client: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>

    func send(_ rec: MirrorBroadcastsIDRecord) async throws {
        let request = Acme_Shows_V1_PeekShowRequest.with {
            $0.showID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekShow(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionValidationService.
struct MirrorBroadcastsIDPrescriptionValidation: MirrorBroadcastsIDSink {
    let client: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>

    func send(_ rec: MirrorBroadcastsIDRecord) async throws {
        _ = try await client.getPrescriptionRules(.with {
            $0.prescriptionID = rec.reportID
        })
    }
}

/// Sends records to acme.careplans.v1.CarePlanValidationService.
struct MirrorBroadcastsIDCarePlanValidation: MirrorBroadcastsIDSink {
    let client: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>

    func send(_ rec: MirrorBroadcastsIDRecord) async throws {
        _ = try await client.getCarePlanRules(.with {
            $0.carePlanID = rec.reportID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct MirrorBroadcastsIDLogOnly: MirrorBroadcastsIDSink {
    let logger = Logger(label: "acme.mirror-broadcasts-id")

    func send(_ rec: MirrorBroadcastsIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.broadcasts.v1.BroadcastQueryService/SummarizeBroadcasts and hands what it keeps to the sink of its kind.
enum MirrorBroadcastsID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: mesh)
        let found = try await source.summarizeBroadcasts(.with { $0.broadcastID = "main-mirror-broadcasts-id" })
        let row = MirrorBroadcastsIDRecord(
            correlationID: Kit.Text.normalize(found.result.correlationID),
            reportID: found.reportID,
            status: found.result.status
        )
        try await deliver("care-plan-validation", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: MirrorBroadcastsIDRecord, _ mesh: MeshClient) async throws {
        var sink: any MirrorBroadcastsIDSink = MirrorBroadcastsIDLogOnly()
        switch kind {
        case "vital-approval":
            sink = MirrorBroadcastsIDVitalApproval(client: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh))
        case "show-query":
            sink = MirrorBroadcastsIDShowQuery(client: Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh))
        case "prescription-validation":
            sink = MirrorBroadcastsIDPrescriptionValidation(client: Acme_Prescriptions_V1_PrescriptionValidationService.Client(wrapping: mesh))
        case "care-plan-validation":
            sink = MirrorBroadcastsIDCarePlanValidation(client: Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
