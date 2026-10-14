import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorAllergySource keeps of each QuoteAllergy response.
struct MirrorAllergySourceRecord {
    var source: String
    var currencyCode: String
}

/// Where MirrorAllergySource hands each record.
protocol MirrorAllergySourceWriter {
    func apply(_ rec: MirrorAllergySourceRecord) async throws
}

/// Passes records to acme.patientapp.v1.PatientHomeNotificationService.
struct MirrorAllergySourcePatientHomeNotification: MirrorAllergySourceWriter {
    let client: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>

    func apply(_ rec: MirrorAllergySourceRecord) async throws {
        _ = try await client.unsubscribePatientHomeUpdates(.with {
            $0.details.channel = rec.currencyCode
        })
    }
}

/// Sends records to acme.licensing.v1.SoftwareLicenseQueryService.
struct MirrorAllergySourceSoftwareLicenseQuery: MirrorAllergySourceWriter {
    let client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>

    func apply(_ rec: MirrorAllergySourceRecord) async throws {
        _ = try await client.lookupSoftwareLicense(.with {
            $0.softwareLicenseID = rec.source
        })
    }
}

/// Passes records to acme.careplans.v1.CarePlanApprovalService.
struct MirrorAllergySourceCarePlanApproval: MirrorAllergySourceWriter {
    let client: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>

    func apply(_ rec: MirrorAllergySourceRecord) async throws {
        _ = try await client.listPendingCarePlans(.with {
            $0.filter.ownerID = rec.source
            $0.page.pageToken = rec.currencyCode
        })
    }
}

/// Sends records to acme.patients.v1.MedicalRecordWorkflowService.
struct MirrorAllergySourceMedicalRecordWorkflow: MirrorAllergySourceWriter {
    let client: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>

    func apply(_ rec: MirrorAllergySourceRecord) async throws {
        let request = Acme_Patients_V1_InspectMedicalRecordWorkflowRequest.with {
            $0.medicalRecordID = rec.source
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.inspectMedicalRecordWorkflow(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct MirrorAllergySourceLogOnly: MirrorAllergySourceWriter {
    let logger = Logger(label: "acme.mirror-allergy-source")

    func apply(_ rec: MirrorAllergySourceRecord) async throws {
        logger.info("No sink for record", metadata: ["source": .string(rec.source)])
    }
}

/// Reads acme.patients.v1.AllergyCalculationService/QuoteAllergy and hands what it keeps to the sink of its kind.
enum MirrorAllergySource {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)
        let response = try await origin.quoteAllergy(.with { $0.allergyID = "primary-mirror-allergy-source" })
        let row = MirrorAllergySourceRecord(
            source: response.allergy.source,
            currencyCode: response.breakdown.currencyCode
        )
        try await deliver("patient-home-notification", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: MirrorAllergySourceRecord, _ mesh: MeshClient) async throws {
        var sink: any MirrorAllergySourceWriter = MirrorAllergySourceLogOnly()
        switch kind {
        case "patient-home-notification":
            sink = MirrorAllergySourcePatientHomeNotification(client: Acme_Patientapp_V1_PatientHomeNotificationService.Client(wrapping: mesh))
        case "software-license-query":
            sink = MirrorAllergySourceSoftwareLicenseQuery(client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh))
        case "care-plan-approval":
            sink = MirrorAllergySourceCarePlanApproval(client: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: mesh))
        case "medical-record-workflow":
            sink = MirrorAllergySourceMedicalRecordWorkflow(client: Acme_Patients_V1_MedicalRecordWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
