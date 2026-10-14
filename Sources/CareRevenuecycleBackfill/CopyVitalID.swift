import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyVitalID keeps of each ApproveVital response.
struct CopyVitalIDRecord {
    var vitalID: String
    var status: String
    var referenceID: String
    var kind: String
}

/// Where CopyVitalID hands each record.
protocol CopyVitalIDTarget {
    func write(_ rec: CopyVitalIDRecord) async throws
}

/// Hands records to acme.patients.v1.AllergyReportingService.
struct CopyVitalIDAllergyReporting: CopyVitalIDTarget {
    let client: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>

    func write(_ rec: CopyVitalIDRecord) async throws {
        let request = Acme_Patients_V1_ListAllergyReportsRequest.with {
            $0.filter.ownerID = rec.vitalID
            $0.filter.region = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listAllergyReports(request)
        }
    }
}

/// Writes records to acme.telehealth.v1.TriageWorkflowService.
struct CopyVitalIDTriageWorkflow: CopyVitalIDTarget {
    let client: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>

    func write(_ rec: CopyVitalIDRecord) async throws {
        _ = try await client.pauseTriageWorkflow(.with {
            $0.triage.subject = rec.status
            $0.reason = rec.vitalID
            $0.triage.triageID = rec.kind
        })
    }
}

/// Reads acme.careplans.v1.VitalApprovalService/ApproveVital and hands what it keeps to the sink of its kind.
enum CopyVitalID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh)
        let reply = try await reader.approveVital(.with { $0.vitalID = "nightly-copy-vital-id" })
        let record = CopyVitalIDRecord(
            vitalID: reply.vital.vitalID,
            status: reply.outcome.status,
            referenceID: reply.outcome.referenceID,
            kind: Kit.Text.normalize(reply.vital.kind)
        )
        try await act("allergy-reporting", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CopyVitalIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "allergy-reporting": { try await CopyVitalIDAllergyReporting(client: Acme_Patients_V1_AllergyReportingService.Client(wrapping: mesh)).write(rec) },
            "triage-workflow": { try await CopyVitalIDTriageWorkflow(client: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)).write(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
