import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about patient homes, for screens and reports.
final class PatientHomeQueryEndpoint: Acme_Patientapp_V1_PatientHomeQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>
    let auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>
    let documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientappPatientHomeNotification: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>
    let patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let exportPatientHomesStep0:
        any RPCPort<Acme_Prescriptions_V1_PushMedicationRequest, Acme_Prescriptions_V1_PushMedicationResponse>
    let exportPatientHomesStep2:
        @Sendable (Acme_Patients_V1_CommentAllergyApprovalRequest) async throws ->
            Acme_Patients_V1_CommentAllergyApprovalResponse
    let exportPatientHomesStep3:
        [String: @Sendable (Acme_Audit_V1_FindAuditEventsRequest) async throws -> Acme_Audit_V1_FindAuditEventsResponse]

    init(
        dependencies: any Dependencies,
        auditAuditEvent: Acme_Audit_V1_AuditEventService.Client<MeshTransport>,
        auditAuditEventQuery: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>,
        documentsDocument: Acme_Documents_V1_DocumentService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientappPatientHomeNotification: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>,
        patientsAllergyApproval: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.auditAuditEvent = auditAuditEvent
        self.auditAuditEventQuery = auditAuditEventQuery
        self.documentsDocument = documentsDocument
        self.identityUser = identityUser
        self.patientappPatientHomeNotification = patientappPatientHomeNotification
        self.patientsAllergyApproval = patientsAllergyApproval
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.exportPatientHomesStep0 = ClosurePort<
            Acme_Prescriptions_V1_PushMedicationRequest, Acme_Prescriptions_V1_PushMedicationResponse
        >({ request in try await prescriptionsMedicationSync.pushMedication(request) })
        self.exportPatientHomesStep2 = { request in try await patientsAllergyApproval.commentAllergyApproval(request) }
        self.exportPatientHomesStep3 = [
            "primary": { request in try await auditAuditEventQuery.findAuditEvents(request) }
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

    /// Lists patient homes a page at a time.
    func browsePatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_BrowsePatientHomesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_BrowsePatientHomesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowsePatientHomes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts patient homes by status.
    func countPatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_CountPatientHomesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_CountPatientHomesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountPatientHomes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching patient home.
    func exportPatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_ExportPatientHomesRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Patientapp_V1_ExportPatientHomesResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportPatientHomes(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists patient homes a page at a time.
    func findPatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_FindPatientHomesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_FindPatientHomesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindPatientHomes(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient home.
    func lookupPatientHome(
        request: ServerRequest<Acme_Patientapp_V1_LookupPatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_LookupPatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupPatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient home.
    func peekPatientHome(
        request: ServerRequest<Acme_Patientapp_V1_PeekPatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_PeekPatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekPatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patient homes a page at a time.
    func suggestPatientHomes(
        request: ServerRequest<Acme_Patientapp_V1_SuggestPatientHomesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SuggestPatientHomesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestPatientHomes(request.message)
            return ServerResponse(message: response)
        }
    }
}
