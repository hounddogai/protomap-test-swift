import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RoutePatientHomeWorkflowsToken keeps of each ListPatientHomeWorkflows response.
struct RoutePatientHomeWorkflowsTokenRecord {
    var nextPageToken: String
    var message: String
}

/// Where RoutePatientHomeWorkflowsToken hands each record.
protocol RoutePatientHomeWorkflowsTokenSink {
    func send(_ rec: RoutePatientHomeWorkflowsTokenRecord) async throws
}

/// Writes records to acme.prescriptions.v1.RefillImportService.
struct RoutePatientHomeWorkflowsTokenRefillImport: RoutePatientHomeWorkflowsTokenSink {
    let client: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>

    func send(_ rec: RoutePatientHomeWorkflowsTokenRecord) async throws {
        _ = try await client.retryRefillImport(.with {
            $0.details.initiatedBy = rec.message
        })
    }
}

/// Passes records to acme.telehealth.v1.TriageWorkflowService.
struct RoutePatientHomeWorkflowsTokenTriageWorkflow: RoutePatientHomeWorkflowsTokenSink {
    let client: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>

    func send(_ rec: RoutePatientHomeWorkflowsTokenRecord) async throws {
        _ = try await client.resumeTriageWorkflow(.with {
            $0.details.initiatedBy = rec.nextPageToken
            $0.details.step = rec.message
        })
    }
}

/// Passes records to acme.careplans.v1.VitalValidationService.
struct RoutePatientHomeWorkflowsTokenVitalValidation: RoutePatientHomeWorkflowsTokenSink {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func send(_ rec: RoutePatientHomeWorkflowsTokenRecord) async throws {
        _ = try await client.lintVitals(.with {
            $0.details.locale = rec.nextPageToken
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RoutePatientHomeWorkflowsTokenLogOnly: RoutePatientHomeWorkflowsTokenSink {
    let logger = Logger(label: "acme.route-patient-home-workflows-token")

    func send(_ rec: RoutePatientHomeWorkflowsTokenRecord) async throws {
        logger.info("No sink for record", metadata: ["nextPageToken": .string(rec.nextPageToken)])
    }
}

/// Reads acme.patientapp.v1.PatientHomeWorkflowService/ListPatientHomeWorkflows and hands what it keeps to the sink of its kind.
enum RoutePatientHomeWorkflowsToken {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)
        let got = try await upstream.listPatientHomeWorkflows(.with { $0.orderBy = "primary-route-patient-home-workflows-token" })
        let row = RoutePatientHomeWorkflowsTokenRecord(
            nextPageToken: Kit.Text.normalize(got.pageInfo.nextPageToken),
            message: got.result.message
        )
        try await dispatch("triage-workflow", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RoutePatientHomeWorkflowsTokenRecord, _ mesh: MeshClient) async throws {
        var write: (RoutePatientHomeWorkflowsTokenRecord) async throws -> Void = RoutePatientHomeWorkflowsTokenLogOnly().send
        switch kind {
        case "refill-import":
            write = RoutePatientHomeWorkflowsTokenRefillImport(client: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: mesh)).send
        case "triage-workflow":
            write = RoutePatientHomeWorkflowsTokenTriageWorkflow(client: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)).send
        case "vital-validation":
            write = RoutePatientHomeWorkflowsTokenVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)).send
        default:
            break
        }
        try await write(rec)
    }
}
