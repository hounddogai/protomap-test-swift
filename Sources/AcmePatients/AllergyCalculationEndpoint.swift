import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of an allergy, such as totals, taxes, and estimates.
final class AllergyCalculationEndpoint: Acme_Patients_V1_AllergyCalculationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    let auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>
    let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let calculateAllergyStep0:
        any RPCPort<Acme_Appointments_V1_ScoreClinicSlotRequest, Acme_Appointments_V1_ScoreClinicSlotResponse>
    let calculateAllergyStep2:
        @Sendable (Acme_Prescriptions_V1_CalculatePrescriptionRequest) async throws ->
            Acme_Prescriptions_V1_CalculatePrescriptionResponse
    let compareAllergyOptionsStep0:
        [String:
            @Sendable (Acme_Audit_V1_CheckAuditEventEligibilityRequest) async throws ->
            Acme_Audit_V1_CheckAuditEventEligibilityResponse]

    init(
        dependencies: any Dependencies,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        auditAuditEventValidation: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesQuery: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.auditAuditEventValidation = auditAuditEventValidation
        self.documentsDocument = documentsDocument
        self.documentsDocumentValidation = documentsDocumentValidation
        self.identityUser = identityUser
        self.metricsMetricSeriesQuery = metricsMetricSeriesQuery
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.telehealthVideoVisit = telehealthVideoVisit
        self.calculateAllergyStep0 = ClosurePort<
            Acme_Appointments_V1_ScoreClinicSlotRequest, Acme_Appointments_V1_ScoreClinicSlotResponse
        >({ request in try await appointmentsClinicSlotValidation.scoreClinicSlot(request) })
        self.calculateAllergyStep2 = { request in
            try await prescriptionsPrescriptionCalculation.calculatePrescription(request)
        }
        self.compareAllergyOptionsStep0 = [
            "primary": { request in try await auditAuditEventValidation.checkAuditEventEligibility(request) }
        ]
    }

    /// Resolve follow-up ownership outside the RPC's lifetime.
    func runFollowUps() async throws {
        for await event in followUps.events {
            try Task.checkCancellation()
            do {
                let user = try await self.identityUser.getUser(event)
                logger.info("Follow-up resolved", metadata: ["user": .string(user.user.userID)])
            } catch {
                logger.error("Follow-up failed", metadata: ["error": .string(String(describing: error))])
            }
        }
    }
}
