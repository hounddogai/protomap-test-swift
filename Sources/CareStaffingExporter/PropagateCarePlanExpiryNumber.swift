import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateCarePlanExpiryNumber keeps of each ScheduleCarePlanExpiry response.
struct PropagateCarePlanExpiryNumberRecord {
    var number: String
    var notes: String
}

/// Where PropagateCarePlanExpiryNumber hands each record.
protocol PropagateCarePlanExpiryNumberDestination {
    func forward(_ rec: PropagateCarePlanExpiryNumberRecord) async throws
}

/// Passes records to acme.patients.v1.MedicalRecordValidationService.
struct PropagateCarePlanExpiryNumberMedicalRecordValidation: PropagateCarePlanExpiryNumberDestination {
    let client: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>

    func forward(_ rec: PropagateCarePlanExpiryNumberRecord) async throws {
        let request = Acme_Patients_V1_CheckMedicalRecordEligibilityRequest.with {
            $0.reason = rec.number
            $0.medicalRecord.medicalRecordID = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.checkMedicalRecordEligibility(request)
        }
    }
}

/// Sends records to acme.careplans.v1.VitalValidationService.
struct PropagateCarePlanExpiryNumberVitalValidation: PropagateCarePlanExpiryNumberDestination {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func forward(_ rec: PropagateCarePlanExpiryNumberRecord) async throws {
        _ = try await client.checkVitalEligibility(.with {
            $0.vital.correlationID = rec.notes
            $0.vital.kind = rec.number
        })
    }
}

/// Sends records to acme.itsm.v1.IncidentQueryService.
struct PropagateCarePlanExpiryNumberIncidentQuery: PropagateCarePlanExpiryNumberDestination {
    let client: Acme_Itsm_V1_IncidentQueryService.Client<MeshTransport>

    func forward(_ rec: PropagateCarePlanExpiryNumberRecord) async throws {
        let request = Acme_Itsm_V1_PeekIncidentRequest.with {
            $0.incidentID = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekIncident(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PropagateCarePlanExpiryNumberLogOnly: PropagateCarePlanExpiryNumberDestination {
    let logger = Logger(label: "acme.propagate-care-plan-expiry-number")

    func forward(_ rec: PropagateCarePlanExpiryNumberRecord) async throws {
        logger.info("No sink for record", metadata: ["number": .string(rec.number)])
    }
}

/// Reads acme.careplans.v1.CarePlanLifecycleService/ScheduleCarePlanExpiry and hands what it keeps to the sink of its kind.
enum PropagateCarePlanExpiryNumber {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)
        let response = try await reader.scheduleCarePlanExpiry(.with { $0.carePlanID = "live-propagate-care-plan-expiry-number" })
        let record = PropagateCarePlanExpiryNumberRecord(
            number: response.carePlan.number,
            notes: response.carePlan.notes
        )
        try await deliver("medical-record-validation", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PropagateCarePlanExpiryNumberRecord, _ mesh: MeshClient) async throws {
        var sink: any PropagateCarePlanExpiryNumberDestination = PropagateCarePlanExpiryNumberLogOnly()
        switch kind {
        case "medical-record-validation":
            sink = PropagateCarePlanExpiryNumberMedicalRecordValidation(client: Acme_Patients_V1_MedicalRecordValidationService.Client(wrapping: mesh))
        case "vital-validation":
            sink = PropagateCarePlanExpiryNumberVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh))
        case "incident-query":
            sink = PropagateCarePlanExpiryNumberIncidentQuery(client: Acme_Itsm_V1_IncidentQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
