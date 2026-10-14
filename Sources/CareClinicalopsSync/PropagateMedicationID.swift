import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateMedicationID keeps of each RejectMedication response.
struct PropagateMedicationIDRecord {
    var correlationID: String
    var message: String
}

/// Where PropagateMedicationID hands each record.
protocol PropagateMedicationIDTarget {
    func push(_ rec: PropagateMedicationIDRecord) async throws
}

/// Writes records to acme.patients.v1.PatientApprovalService.
struct PropagateMedicationIDPatientApproval: PropagateMedicationIDTarget {
    let client: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>

    func push(_ rec: PropagateMedicationIDRecord) async throws {
        _ = try await client.delegatePatientApproval(.with {
            $0.reason = rec.correlationID
            $0.patient.patientID = rec.message
        })
    }
}

/// Writes records to acme.sponsorships.v1.SponsorCalculationService.
struct PropagateMedicationIDSponsorCalculation: PropagateMedicationIDTarget {
    let client: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>

    func push(_ rec: PropagateMedicationIDRecord) async throws {
        _ = try await client.simulateSponsor(.with {
            $0.details.currencyCode = rec.message
        })
    }
}

/// Passes records to acme.pipelines.v1.PipelineCalculationService.
struct PropagateMedicationIDPipelineCalculation: PropagateMedicationIDTarget {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func push(_ rec: PropagateMedicationIDRecord) async throws {
        let request = Acme_Pipelines_V1_RecalculatePipelinesRequest.with {
            $0.pipelineID = rec.message
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.recalculatePipelines(request)
        }
    }
}

/// Sends records to acme.telehealth.v1.VideoVisitCalculationService.
struct PropagateMedicationIDVideoVisitCalculation: PropagateMedicationIDTarget {
    let client: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>

    func push(_ rec: PropagateMedicationIDRecord) async throws {
        _ = try await client.compareVideoVisitOptions(.with {
            $0.details.currencyCode = rec.message
            $0.videoVisit.videoVisitID = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct PropagateMedicationIDLogOnly: PropagateMedicationIDTarget {
    let logger = Logger(label: "acme.propagate-medication-id")

    func push(_ rec: PropagateMedicationIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.prescriptions.v1.MedicationApprovalService/RejectMedication and hands what it keeps to the sink of its kind.
enum PropagateMedicationID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh)
        let got = try await reader.rejectMedication(.with { $0.medicationID = "live-propagate-medication-id" })
        let rec = PropagateMedicationIDRecord(
            correlationID: got.result.correlationID,
            message: got.result.message
        )
        try await deliver("patient-approval", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PropagateMedicationIDRecord, _ mesh: MeshClient) async throws {
        var sink: any PropagateMedicationIDTarget = PropagateMedicationIDLogOnly()
        switch kind {
        case "patient-approval":
            sink = PropagateMedicationIDPatientApproval(client: Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh))
        case "sponsor-calculation":
            sink = PropagateMedicationIDSponsorCalculation(client: Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh))
        case "pipeline-calculation":
            sink = PropagateMedicationIDPipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh))
        case "video-visit-calculation":
            sink = PropagateMedicationIDVideoVisitCalculation(client: Acme_Telehealth_V1_VideoVisitCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
