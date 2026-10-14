import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Runs the long-lived workflow that takes a patient from start to finish.
final class PatientWorkflowEndpoint: Acme_Patients_V1_PatientWorkflowService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    let patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>
    let patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>
    let prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>
    let prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>
    let prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        patientsMedicalRecordApproval: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>,
        patientsPatientReporting: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>,
        prescriptionsPrescriptionApproval: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>,
        prescriptionsPrescriptionSync: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>,
        prescriptionsRefillApproval: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicy = authorizationAccessPolicy
        self.identityUser = identityUser
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.patientsMedicalRecordApproval = patientsMedicalRecordApproval
        self.patientsPatientReporting = patientsPatientReporting
        self.prescriptionsPrescriptionApproval = prescriptionsPrescriptionApproval
        self.prescriptionsPrescriptionSync = prescriptionsPrescriptionSync
        self.prescriptionsRefillApproval = prescriptionsRefillApproval
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.venuesVenueValidation = venuesVenueValidation
    }

    /// Advances a patient.
    func advancePatientWorkflow(
        request: ServerRequest<Acme_Patients_V1_AdvancePatientWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_AdvancePatientWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processAdvancePatientWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Cancels a patient.
    func cancelPatientWorkflow(
        request: ServerRequest<Acme_Patients_V1_CancelPatientWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CancelPatientWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCancelPatientWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient.
    func inspectPatientWorkflow(
        request: ServerRequest<Acme_Patients_V1_InspectPatientWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_InspectPatientWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processInspectPatientWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Retrys a patient.
    func retryPatientWorkflow(
        request: ServerRequest<Acme_Patients_V1_RetryPatientWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_RetryPatientWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRetryPatientWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Signals a patient.
    func signalPatientWorkflow(
        request: ServerRequest<Acme_Patients_V1_SignalPatientWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SignalPatientWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSignalPatientWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a patient.
    func startPatientWorkflow(
        request: ServerRequest<Acme_Patients_V1_StartPatientWorkflowRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_StartPatientWorkflowResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartPatientWorkflow(request.message)
            return ServerResponse(message: response)
        }
    }
}
