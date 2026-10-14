import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Moves an allergy between the states of its lifecycle.
final class AllergyLifecycleEndpoint: Acme_Patients_V1_AllergyLifecycleService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>
    let careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>
    let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let localizationTranslationKeyCalculation:
        Acme_Localization_V1_TranslationKeyCalculationService.Client<MeshTransport>
    let patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>
    let patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>
    let patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>
    let renewAllergyStep1:
        any RPCPort<Acme_Documents_V1_PreviewDocumentRequest, Acme_Documents_V1_PreviewDocumentResponse>
    let scheduleAllergyExpiryStep1:
        @Sendable (Acme_Patients_V1_PushPatientRequest) async throws -> Acme_Patients_V1_PushPatientResponse
    let suspendAllergyStep0:
        [String:
            @Sendable (Acme_Patients_V1_ShareMedicalRecordReportRequest) async throws ->
            Acme_Patients_V1_ShareMedicalRecordReportResponse]

    init(
        dependencies: any Dependencies,
        careplansCarePlanApproval: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>,
        careplansCarePlanWorkflow: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        localizationTranslationKeyCalculation: Acme_Localization_V1_TranslationKeyCalculationService.Client<
            MeshTransport
        >,
        patientsAllergyImport: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>,
        patientsMedicalRecordReporting: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>,
        patientsMedicalRecordSync: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        patientsPatientSync: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCarePlanApproval = careplansCarePlanApproval
        self.careplansCarePlanWorkflow = careplansCarePlanWorkflow
        self.documentsDocumentValidation = documentsDocumentValidation
        self.identityUser = identityUser
        self.localizationTranslationKeyCalculation = localizationTranslationKeyCalculation
        self.patientsAllergyImport = patientsAllergyImport
        self.patientsMedicalRecordReporting = patientsMedicalRecordReporting
        self.patientsMedicalRecordSync = patientsMedicalRecordSync
        self.patientsPatientCalculation = patientsPatientCalculation
        self.patientsPatientSync = patientsPatientSync
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.telehealthVisitNoteApproval = telehealthVisitNoteApproval
        self.renewAllergyStep1 = ClosurePort<
            Acme_Documents_V1_PreviewDocumentRequest, Acme_Documents_V1_PreviewDocumentResponse
        >({ request in try await documentsDocumentValidation.previewDocument(request) })
        self.scheduleAllergyExpiryStep1 = { request in try await patientsPatientSync.pushPatient(request) }
        self.suspendAllergyStep0 = [
            "primary": { request in try await patientsMedicalRecordReporting.shareMedicalRecordReport(request) }
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

    /// Activates an allergy.
    func activateAllergy(
        request: ServerRequest<Acme_Patients_V1_ActivateAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ActivateAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processActivateAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Expires an allergy.
    func expireAllergy(
        request: ServerRequest<Acme_Patients_V1_ExpireAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ExpireAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExpireAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an allergy.
    func getAllergyLifecycle(
        request: ServerRequest<Acme_Patients_V1_GetAllergyLifecycleRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetAllergyLifecycleResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAllergyLifecycle(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Reinstates an allergy.
    func reinstateAllergy(
        request: ServerRequest<Acme_Patients_V1_ReinstateAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ReinstateAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processReinstateAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Renews an allergy.
    func renewAllergy(
        request: ServerRequest<Acme_Patients_V1_RenewAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RenewAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRenewAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules an allergy.
    func scheduleAllergyExpiry(
        request: ServerRequest<Acme_Patients_V1_ScheduleAllergyExpiryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ScheduleAllergyExpiryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleAllergyExpiry(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Suspends an allergy.
    func suspendAllergy(
        request: ServerRequest<Acme_Patients_V1_SuspendAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SuspendAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuspendAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Terminates an allergy.
    func terminateAllergy(
        request: ServerRequest<Acme_Patients_V1_TerminateAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_TerminateAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTerminateAllergy(request.message)
            return ServerResponse(message: response)
        }
    }
}
