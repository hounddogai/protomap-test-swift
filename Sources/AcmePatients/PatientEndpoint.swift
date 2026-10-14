import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Manages patients: creates, reads, changes, and lists them.
final class PatientEndpoint: Acme_Patients_V1_PatientService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    let authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>
    let patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>
    let telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    let createPatientStep0:
        any RPCPort<Acme_Appointments_V1_CountAppointmentsRequest, Acme_Appointments_V1_CountAppointmentsResponse>
    let deletePatientStep0:
        @Sendable (Acme_Patients_V1_PeekPatientRequest) async throws -> Acme_Patients_V1_PeekPatientResponse
    let getPatientStep0:
        [String:
            @Sendable (Acme_Patients_V1_LintMedicalRecordsRequest) async throws ->
            Acme_Patients_V1_LintMedicalRecordsResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        authorizationAccessPolicyQuery: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsMedicalRecordValidation: Acme_Patients_V1_MedicalRecordValidationService.Client<MeshTransport>,
        patientsPatientQuery: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        searchSearchIndexQuery: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>,
        telehealthTriageCalculation: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.authorizationAccessPolicyQuery = authorizationAccessPolicyQuery
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.identityUser = identityUser
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsMedicalRecordValidation = patientsMedicalRecordValidation
        self.patientsPatientQuery = patientsPatientQuery
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.searchSearchIndexQuery = searchSearchIndexQuery
        self.telehealthTriageCalculation = telehealthTriageCalculation
        self.createPatientStep0 = ClosurePort<
            Acme_Appointments_V1_CountAppointmentsRequest, Acme_Appointments_V1_CountAppointmentsResponse
        >({ request in try await appointmentsAppointmentQuery.countAppointments(request) })
        self.deletePatientStep0 = { request in try await patientsPatientQuery.peekPatient(request) }
        self.getPatientStep0 = [
            "primary": { request in try await patientsMedicalRecordValidation.lintMedicalRecords(request) }
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

    /// Takes a stream of patients and answers once at the end.
    func batchCreatePatients(
        request: StreamingServerRequest<Acme_Patients_V1_BatchCreatePatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_BatchCreatePatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Patients_V1_BatchCreatePatientsResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processBatchCreatePatients(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }

    /// Returns several patients at once.
    func batchGetPatients(
        request: ServerRequest<Acme_Patients_V1_BatchGetPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_BatchGetPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBatchGetPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a patient.
    func clonePatient(
        request: ServerRequest<Acme_Patients_V1_ClonePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ClonePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processClonePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Creates a patient.
    func createPatient(
        request: ServerRequest<Acme_Patients_V1_CreatePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CreatePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCreatePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a patient.
    func deletePatient(
        request: ServerRequest<Acme_Patients_V1_DeletePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_DeletePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeletePatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient.
    func getPatient(
        request: ServerRequest<Acme_Patients_V1_GetPatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetPatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPatient(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patients a page at a time.
    func listPatients(
        request: ServerRequest<Acme_Patients_V1_ListPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ListPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patients a page at a time.
    func searchPatients(
        request: ServerRequest<Acme_Patients_V1_SearchPatientsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_SearchPatientsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSearchPatients(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Changes a patient.
    func updatePatient(
        request: ServerRequest<Acme_Patients_V1_UpdatePatientRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_UpdatePatientResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processUpdatePatient(request.message)
            return ServerResponse(message: response)
        }
    }
}
