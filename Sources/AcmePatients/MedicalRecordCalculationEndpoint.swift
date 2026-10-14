import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Computes the figures of a medical record, such as totals, taxes, and estimates.
final class MedicalRecordCalculationEndpoint: Acme_Patients_V1_MedicalRecordCalculationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    let patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>
    let prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>
    let telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>
    let venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    let simulateMedicalRecordStep1:
        any RPCPort<Acme_Prescriptions_V1_CalculateRefillRequest, Acme_Prescriptions_V1_CalculateRefillResponse>

    init(
        dependencies: any Dependencies,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        patientsPatientCalculation: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        prescriptionsPrescriptionQuery: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>,
        prescriptionsRefillCalculation: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>,
        telehealthVisitNoteQuery: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>,
        venuesVenue: Acme_Venues_V1_VenueService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.documentsDocumentValidation = documentsDocumentValidation
        self.identityUser = identityUser
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.patientsPatientCalculation = patientsPatientCalculation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.prescriptionsPrescriptionQuery = prescriptionsPrescriptionQuery
        self.prescriptionsRefillCalculation = prescriptionsRefillCalculation
        self.telehealthVisitNoteQuery = telehealthVisitNoteQuery
        self.venuesVenue = venuesVenue
        self.simulateMedicalRecordStep1 = ClosurePort<
            Acme_Prescriptions_V1_CalculateRefillRequest, Acme_Prescriptions_V1_CalculateRefillResponse
        >({ request in try await prescriptionsRefillCalculation.calculateRefill(request) })
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

    /// Calculates a medical record.
    func calculateMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_CalculateMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CalculateMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCalculateMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Compares a medical record.
    func compareMedicalRecordOptions(
        request: ServerRequest<Acme_Patients_V1_CompareMedicalRecordOptionsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CompareMedicalRecordOptionsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCompareMedicalRecordOptions(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Estimates a medical record.
    func estimateMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_EstimateMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_EstimateMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processEstimateMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Explains a medical record.
    func explainMedicalRecordCalculation(
        request: ServerRequest<Acme_Patients_V1_ExplainMedicalRecordCalculationRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ExplainMedicalRecordCalculationResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processExplainMedicalRecordCalculation(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a medical record.
    func getMedicalRecordRates(
        request: ServerRequest<Acme_Patients_V1_GetMedicalRecordRatesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetMedicalRecordRatesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetMedicalRecordRates(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Quotes a medical record.
    func quoteMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_QuoteMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_QuoteMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processQuoteMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Simulates a medical record.
    func simulateMedicalRecord(
        request: ServerRequest<Acme_Patients_V1_SimulateMedicalRecordRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SimulateMedicalRecordResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSimulateMedicalRecord(request.message)
            return ServerResponse(message: response)
        }
    }
}
