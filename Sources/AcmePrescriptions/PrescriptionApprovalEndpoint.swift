import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Routes prescriptions through approval, with escalation and delegation.
final class PrescriptionApprovalEndpoint: Acme_Prescriptions_V1_PrescriptionApprovalService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>
    let patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionLifecycle: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client<MeshTransport>
    let prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>
    let prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>
    let prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>
    let prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>
    let telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>
    let telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountValidation: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>,
        patientsAllergyValidation: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsMedicationSync: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionLifecycle: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client<MeshTransport>,
        prescriptionsPrescriptionReporting: Acme_Prescriptions_V1_PrescriptionReportingService.Client<MeshTransport>,
        prescriptionsRefillImport: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>,
        prescriptionsRefillLifecycle: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>,
        prescriptionsRefillSync: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>,
        telehealthTriageWorkflow: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>,
        telehealthVisitNoteApproval: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.identityUser = identityUser
        self.ledgerLedgerAccountValidation = ledgerLedgerAccountValidation
        self.patientsAllergyValidation = patientsAllergyValidation
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsMedicationSync = prescriptionsMedicationSync
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescriptionLifecycle = prescriptionsPrescriptionLifecycle
        self.prescriptionsPrescriptionReporting = prescriptionsPrescriptionReporting
        self.prescriptionsRefillImport = prescriptionsRefillImport
        self.prescriptionsRefillLifecycle = prescriptionsRefillLifecycle
        self.prescriptionsRefillSync = prescriptionsRefillSync
        self.telehealthTriageWorkflow = telehealthTriageWorkflow
        self.telehealthVisitNoteApproval = telehealthVisitNoteApproval
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

    /// Approves a prescription.
    func approvePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_ApprovePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ApprovePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processApprovePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Comments a prescription.
    func commentPrescriptionApproval(
        request: ServerRequest<Acme_Prescriptions_V1_CommentPrescriptionApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_CommentPrescriptionApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCommentPrescriptionApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Delegates a prescription.
    func delegatePrescriptionApproval(
        request: ServerRequest<Acme_Prescriptions_V1_DelegatePrescriptionApprovalRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_DelegatePrescriptionApprovalResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDelegatePrescriptionApproval(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Escalates a prescription.
    func escalatePrescription(
        request: ServerRequest<Acme_Prescriptions_V1_EscalatePrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_EscalatePrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEscalatePrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a prescription.
    func getPrescriptionApprovalStatus(
        request: ServerRequest<Acme_Prescriptions_V1_GetPrescriptionApprovalStatusRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_GetPrescriptionApprovalStatusResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPrescriptionApprovalStatus(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists prescriptions a page at a time.
    func listPendingPrescriptions(
        request: ServerRequest<Acme_Prescriptions_V1_ListPendingPrescriptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_ListPendingPrescriptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPendingPrescriptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Recalls a prescription.
    func recallPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_RecallPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RecallPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRecallPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Rejects a prescription.
    func rejectPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_RejectPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_RejectPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRejectPrescription(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a prescription.
    func submitPrescription(
        request: ServerRequest<Acme_Prescriptions_V1_SubmitPrescriptionRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Prescriptions_V1_SubmitPrescriptionResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitPrescription(request.message)
            return ServerResponse(message: response)
        }
    }
}
